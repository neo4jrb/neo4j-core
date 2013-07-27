require 'spec_helper'

describe Neo4j::Server::CypherDatabase do
  describe 'instance methods' do

    describe 'create_node' do
      let(:create_node_cypher_json) do
        JSON.parse <<-HERE
      {
       "columns" : [ "v1" ],
       "data" : [ [ {
         "outgoing_relationships" : "http://localhost:7474/db/data/node/1915/relationships/out",
         "labels" : "http://localhost:7474/db/data/node/1915/labels",
         "data" : {
         },
         "all_typed_relationships" : "http://localhost:7474/db/data/node/1915/relationships/all/{-list|&|types}",
         "traverse" : "http://localhost:7474/db/data/node/1915/traverse/{returnType}",
         "self" : "http://localhost:7474/db/data/node/1915",
         "property" : "http://localhost:7474/db/data/node/1915/properties/{key}",
         "outgoing_typed_relationships" : "http://localhost:7474/db/data/node/1915/relationships/out/{-list|&|types}",
         "properties" : "http://localhost:7474/db/data/node/1915/properties",
         "incoming_relationships" : "http://localhost:7474/db/data/node/1915/relationships/in",
         "extensions" : {
         },
         "create_relationship" : "http://localhost:7474/db/data/node/1915/relationships",
         "paged_traverse" : "http://localhost:7474/db/data/node/1915/paged/traverse/{returnType}{?pageSize,leaseTime}",
         "all_relationships" : "http://localhost:7474/db/data/node/1915/relationships/all",
         "incoming_typed_relationships" : "http://localhost:7474/db/data/node/1915/relationships/in/{-list|&|types}"
       } ] ]
     }
        HERE
      end

      before do
        Neo4j::Server::RestDatabase.any_instance.stub(:connect_to_server)
      end

      let(:db) { Neo4j::Server::CypherDatabase.new('http://endpoint')}

      it "create_node() generates 'CREATE (v1) RETURN v1'" do
        db.should_receive(:_query).with("CREATE (v1) RETURN v1").and_return(create_node_cypher_json)

        db.create_node
      end

      it 'create_node(name: "jimmy") generates ' do
        db.should_receive(:_query).with("CREATE (v1 {name : 'jimmy'}) RETURN v1").and_return(create_node_cypher_json)
        db.create_node(name: 'jimmy')
      end

      it 'create_node({}, [:person])' do
        db.should_receive(:_query).with("CREATE (v1:`person`) RETURN v1").and_return(create_node_cypher_json)
        db.create_node({}, [:person])
      end

      it "initialize a CypherNode instance" do
        db.should_receive(:_query).with("CREATE (v1) RETURN v1").and_return(create_node_cypher_json)
        n = double("cypher node")
        Neo4j::Server::CypherNode.should_receive(:new).and_return(n)
        n.should_receive(:init_resource_data).with  do |node_data, url|
          node_data['self'].should == 'http://localhost:7474/db/data/node/1915'
          url.should == 'http://localhost:7474/db/data/node/1915'
        end

        db.create_node
      end
    end

  end
end
