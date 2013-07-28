require 'spec_helper'

describe Neo4j::Server::RestDatabase do
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

  describe 'instance methods' do
    describe 'connect_to_server' do
      it 'initialize the resource if a 200 response' do
        body1 = <<-HERE
        {
          "management" : "http://localhost:7474/db/manage/",
          "data" : "http://localhost:7474/db/data/"
        }
        HERE
        response1 = Struct.new(:body, :code).new(body1, 200)

        body2 = <<-HERE
        {
        "extensions" : {
        },
        "node" : "http://localhost:7474/db/data/node",
        "reference_node" : "http://localhost:7474/db/data/node/0",
        "node_index" : "http://localhost:7474/db/data/index/node",
        "relationship_index" : "http://localhost:7474/db/data/index/relationship",
        "extensions_info" : "http://localhost:7474/db/data/ext",
        "relationship_types" : "http://localhost:7474/db/data/relationship/types",
        "batch" : "http://localhost:7474/db/data/batch",
        "cypher" : "http://localhost:7474/db/data/cypher",
        "transaction" : "http://localhost:7474/db/data/transaction",
        "neo4j_version" : "2.0.0-M03"
        }
        HERE

        response2 = Struct.new(:body, :code).new(body2, 200)
        HTTParty.should_receive(:get).with('http://url').and_return(response1)
        HTTParty.should_receive(:get).with('http://localhost:7474/db/data/').and_return(response2)
        Neo4j::Server::RestDatabase.new('http://url')
      end
    end

    describe 'create_node' do

      before do
        Neo4j::Server::RestDatabase.any_instance.stub(:connect_to_server)
      end

      let(:db) { Neo4j::Server::RestDatabase.new('http://endpoint')}

      it "create_node() does a post to /node'" do
        db.should_receive(:resource_url).with(:node).and_return("http://my/node")
        HTTParty.should_receive(:post).with do |url, args|
          url.should == 'http://my/node'
        end.and_return(double("response", body: {properties: 'http://ab.c'}.to_json, headers: {location: 'http://my/node/42'}))
        node = db.create_node
        node.resource_data.should == {"properties" => "http://ab.c"}
      end

      it 'create_node(name: "jimmy") post with properties' do
        db.should_receive(:resource_url).with(:node).and_return("http://my/node")
        HTTParty.should_receive(:post).with do |url, args|
          url.should == 'http://my/node'
          JSON.parse(args[:body])['name'].should == 'jimmy'
        end.and_return(double("response", body: {properties: 'http://ab.c'}.to_json, headers: {location: 'http://my/node/42'}))
        node = db.create_node(name: 'jimmy')
        node.resource_data.should == {"properties" => "http://ab.c"}
      end

      it 'create_node({}, [:person])' do
        pending
        db.should_receive(:resource_url).with(:node).and_return("http://my/node")
        db.create_node({}, [:person])
        RestNode.any_instance
      end

    end

  end
end