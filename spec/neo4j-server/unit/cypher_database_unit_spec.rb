require 'spec_helper'

describe Neo4j::Server::CypherDatabase do
  before do
    Neo4j::Server::RestDatabase.any_instance.stub(:connect_to_server)
  end

  let(:db) { Neo4j::Server::CypherDatabase.new('http://endpoint')}

  let(:create_node_cypher_json) do
    response = JSON.parse <<-HERE
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
    response.stub(:code).and_return(200)
    response.stub(:request).and_return(double('request', path: 'http:://request.com'))
    response
  end

  describe 'instance methods' do

    describe 'load_node' do
      it "generates 'START v0 = node(1915); RETURN v0'" do
        db.should_receive(:_query).with("START v1=node(1915) RETURN v1").and_return(create_node_cypher_json)
        db.load_node(1915)
      end
    end

    describe 'begin_tx' do
      let(:dummy_request) { double("dummy request", path: 'http://dummy.request')}

      let(:body) do
        <<-HERE
{"commit":"http://localhost:7474/db/data/transaction/1/commit","results":[],"transaction":{"expires":"Tue, 06 Aug 2013 21:35:20 +0000"},"errors":[]}
        HERE
      end

      it "create a new transaction and stores it in thread local" do
        response = double('response', headers: {'location' => 'http://tx/42'}, code: 201, request: dummy_request)
        response.should_receive(:[]).with('commit').and_return('http://tx/42/commit')
        db.should_receive(:resource_url).with('transaction').and_return('http://new.tx')
        HTTParty.should_receive(:post).with('http://new.tx').and_return(response)
        tx = db.begin_tx
        tx.commit_url.should == 'http://tx/42/commit'
        tx.exec_url.should == 'http://tx/42'
        Thread.current[:neo4j_curr_tx].should == tx
      end
    end

    describe 'create_node' do

      before do
        db.stub(:resource_url).and_return("http://resource_url")
      end

      it "create_node() generates 'CREATE (v1) RETURN v1'" do
        db.stub(:resource_url).and_return
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
