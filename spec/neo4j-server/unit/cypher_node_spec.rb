require 'spec_helper'

describe Neo4j::Server::CypherNode do

  describe 'class methods' do

    describe 'create_node' do
      let(:create_node_cypher_json) do
        JSON.parse <<HERE
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

      it "generate: CREATE (v1) RETURN v1" do
        Neo4j::Server::CypherNode.should_receive(:exec_cypher).with("CREATE (v1) RETURN v1").and_return(create_node_cypher_json)
        Neo4j::Server::CypherNode.create_node
      end

      it "initialize a CypherNode instance" do
        Neo4j::Server::CypherNode.should_receive(:exec_cypher).and_return(create_node_cypher_json)
        n = double("cypher node")
        Neo4j::Server::CypherNode.should_receive(:new).and_return(n)
        n.should_receive(:init_resource_data).with do |node_data, url|
          node_data['self'].should == 'http://localhost:7474/db/data/node/1915'
          url.should == 'http://localhost:7474/db/data/node/1915'
        end
        Neo4j::Server::CypherNode.create_node
      end
    end
  end

  describe 'instance methods' do
    describe '[]=' do
      it 'generates correct cypher' do
        node = Neo4j::Server::CypherNode.new
        node.should_receive(:resource_url_id).and_return(42)
        Neo4j::Server::CypherNode.should_receive(:exec_cypher).with('START v1=node(42) SET v1.name = "andreas" RETURN v1')
        node['name'] = 'andreas'
      end
    end

    describe '[]' do
      let(:cypher_response) do
        JSON.parse <<-HERE
        {
          "columns" : [ "n.name" ],
           "data" : [ [ "andreas" ] ]
        }
        HERE
      end

      it 'generates correct cypher' do
        node = Neo4j::Server::CypherNode.new
        node.should_receive(:resource_url_id).and_return(42)
        Neo4j::Server::CypherNode.should_receive(:exec_cypher).with('START v1=node(42) RETURN v1.name').and_return(cypher_response)
        node['name']
      end

      it "should parse the return value from the cypher query" do
        Neo4j::Server::CypherNode.should_receive(:exec_cypher).and_return(cypher_response)
        node = Neo4j::Server::CypherNode.new
        node.should_receive(:resource_url_id).and_return(42)
        node['name'].should == 'andreas'
      end
    end

  end
end