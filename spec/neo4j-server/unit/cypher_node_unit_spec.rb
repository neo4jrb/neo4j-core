require 'spec_helper'

module Neo4j::Server
  describe CypherNode do

    let(:session) do
      allow_any_instance_of(CypherSession).to receive(:initialize_resource)
      CypherSession.new('http://an.url', connection)
    end

    let(:connection) do
      double('connection')
    end

    describe 'instance methods' do

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
          node = CypherNode.new(session, 42)
          expect(session).to receive(:_query_entity_data).with("START n=node(42) RETURN n").and_return({'data'=> {'name'=>'andreas'}})
          expect(node.props).to eq({name: 'andreas'})
        end
      end

      describe 'exist?' do
        it "generates correct cypher" do
          cypher_response = double("cypher response", error?: false)
          expect(session).to receive(:_query).with('START n=node(42) RETURN ID(n)').and_return(cypher_response)
          node = CypherNode.new(session, 42)
          node.init_resource_data('data', 'http://bla/42')

          # when
          node.exist?
        end

        it "returns true if HTTP 200" do
          node = CypherNode.new(session, 42)
          node.init_resource_data('data', 'http://bla/42')
          expect(session).to receive(:_query).and_return(double('response', error?: false))

          expect(node.exist?).to be true
        end

        it "raise exception if unexpected response" do
          node = CypherNode.new(session, 42)
          response = double('response', error?: true, error_status: 'Unknown')
          expect(response).to receive(:raise_error)
          expect(session).to receive(:_query).with('START n=node(42) RETURN ID(n)').and_return(response)
          node.exist?
        end

        it "returns false if HTTP 400 is received with EntityNotFoundException exception" do
          node = CypherNode.new(session, 42)
          response = double("response", error?: true, error_status: 'EntityNotFoundException')
          expect(session).to receive(:_query).with('START n=node(42) RETURN ID(n)').and_return(response)
          expect(node.exist?).to be false
        end
      end

      describe '[]=' do
        it 'generates correct cypher' do
          node = CypherNode.new(session, 42)
          response = double("cypher response", error?: false)
          expect(session).to receive(:_query).with('START n=node(42) SET n.`name` = { value }', {value: 'andreas'}).and_return(response)
          node['name'] = 'andreas'
        end

        it 'removed property if setting it to a nil value' do
          node = CypherNode.new(session, 42)
          response = double("cypher response", error?: false)
          expect(session).to receive(:_query).with('START n=node(42) REMOVE n.`name`',nil).and_return(response)
          node['name'] = nil
        end
      end

      describe '[]' do
        it 'generates correct cypher' do
          node = CypherNode.new(session, 42)
          response = double('cypher response',first_data: 'andreas', error?: false)
          expect(session).to receive(:_query).with('START n=node(42) RETURN n.`name`',nil).and_return(response)
          expect(node['name']).to eq('andreas')
        end
      end

    end
  end  
end
