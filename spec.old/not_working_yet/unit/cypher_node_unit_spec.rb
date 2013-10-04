require 'spec_helper'

describe Neo4j::Server::CypherNode do

  class MockDatabase
    def query(*params, &query_dsl)
      _query Neo4j::Cypher.query(*params, &query_dsl).to_s
    end

    def _query(q)
    end
  end

  describe 'instance methods' do

    let(:db) { MockDatabase.new}

    describe 'props' do
      let(:cypher_body) do
        JSON.parse <<-HERE
        {
          "columns" : [ "a" ],
          "data" : [ [ {
            "outgoing_relationships" : "http://localhost:7474/db/data/node/43/relationships/out",
            "labels" : "http://localhost:7474/db/data/node/43/labels",
            "data" : {
              "name" : "andreas"
            },
            "all_typed_relationships" : "http://localhost:7474/db/data/node/43/relationships/all/{-list|&|types}",
            "traverse" : "http://localhost:7474/db/data/node/43/traverse/{returnType}",
            "self" : "http://localhost:7474/db/data/node/43",
            "property" : "http://localhost:7474/db/data/node/43/properties/{key}",
            "outgoing_typed_relationships" : "http://localhost:7474/db/data/node/43/relationships/out/{-list|&|types}",
            "properties" : "http://localhost:7474/db/data/node/43/properties",
            "incoming_relationships" : "http://localhost:7474/db/data/node/43/relationships/in",
            "extensions" : {
            },
            "create_relationship" : "http://localhost:7474/db/data/node/43/relationships",
            "paged_traverse" : "http://localhost:7474/db/data/node/43/paged/traverse/{returnType}{?pageSize,leaseTime}",
            "all_relationships" : "http://localhost:7474/db/data/node/43/relationships/all",
            "incoming_typed_relationships" : "http://localhost:7474/db/data/node/43/relationships/in/{-list|&|types}"
          } ] ]
        }
      HERE
      end

      let(:cypher_response) do
        double('cypher response', error?: false, first_data: cypher_body['data'][0][0])
      end

      it "returns all properties" do
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')

        db.should_receive(:_query).with('START v1=node(42) RETURN v1').and_return(cypher_response)
        node.props.should == {name: 'andreas'}
      end
    end

    describe 'del' do
      let(:cypher_response) do
        double('cypher response', error?: false)
      end

      it 'generates "START v1=node(42) DELETE v1"' do
        cypher_response.should_receive(:raise_unless_response_code)
        db.should_receive(:_query).with('START v1=node(42) DELETE v1').and_return(cypher_response)
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')


        # when
        node.del
      end
    end

    describe 'exist?' do
      it "generates correct cypher" do
        cypher_response = double("cypher response", error?: false)
        db.should_receive(:_query).with('START v1=node(42) RETURN v1').and_return(cypher_response)
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')

        # when
        node.exist?
      end

      it "returns true if HTTP 200" do
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')
        db.should_receive(:_query).and_return(double('response', error?: false))

        node.exist?.should be_true
      end

      it "raise exception if unexpected response" do
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')
        request = double('request', path:'')
        db.should_receive(:_query).and_return(double('response', error?: true, exception: 'UnknownException', response: double('response').as_null_object))
        expect{node.exist?}.to raise_error(Neo4j::Server::Resource::ServerException)
      end

      it "returns false if HTTP 400 is received with EntityNotFoundException exception" do
        node = Neo4j::Server::CypherNode.new(db)
        node.init_resource_data('data', 'http://bla/42')
        db.should_receive(:_query).and_return(double("response", error?: true, exception: 'EntityNotFoundException'))
        node.exist?.should be_false
      end
    end

    describe '[]=' do
      it 'generates correct cypher' do
        node = Neo4j::Server::CypherNode.new(db)
        node.should_receive(:resource_url_id).and_return(42)
        db.should_receive(:_query).with('START v1=node(42) SET v1.name = "andreas"')
        node['name'] = 'andreas'
      end
    end

    describe '[]' do
      it 'generates correct cypher' do
        node = Neo4j::Server::CypherNode.new(db)
        node.should_receive(:resource_url_id).and_return(42)
        db.should_receive(:_query).with('START v1=node(42) RETURN v1.name?').and_return(double('cypher response',first_data: 'andreas'))
        node['name'].should == 'andreas'
      end
    end

  end
end