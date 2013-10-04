require 'spec_helper'

describe Neo4j::Server::CypherDatabase do
  let(:session) { Neo4j::Server::CypherSession.new}

  let(:cypher_response) do
    double('cypher response', error?: false, first_data: [28])
  end

  describe 'instance methods' do

    describe 'load_node' do
      it "generates 'START v0 = node(1915); RETURN v0'" do
        session.should_receive(:_query).with("START v1=node(1915) RETURN v1").and_return(cypher_response)
        node = session.load_node(1915)
        node.neo_id.should == 1915
      end

      it "returns nil if EntityNotFoundException" do
        r = double('cypher response', error?: true, exception: 'EntityNotFoundException')
        session.should_receive(:_query).with("START v1=node(1915) RETURN v1").and_return(r)
        session.load_node(1915).should be_nil
      end

      it "raise an exception if there is an error but not an EntityNotFoundException exception" do
        r = double('cypher response', error?: true, exception: 'SomeError', response: double("response").as_null_object)
        session.should_receive(:_query).with("START v1=node(1915) RETURN v1").and_return(r)
        expect{session.load_node(1915)}.to raise_error(Neo4j::Server::Resource::ServerException)
      end
    end

    describe 'begin_tx' do
      let(:dummy_request) { double("dummy request", path: 'http://dummy.request')}

      after { Thread.current[:neo4j_curr_tx] = nil }

      let(:body) do
        <<-HERE
{"commit":"http://localhost:7474/db/data/transaction/1/commit","results":[],"transaction":{"expires":"Tue, 06 Aug 2013 21:35:20 +0000"},"errors":[]}
        HERE
      end

      it "create a new transaction and stores it in thread local" do
        response = double('response', headers: {'location' => 'http://tx/42'}, code: 201, request: dummy_request)
        response.should_receive(:[]).with('exception').and_return(nil)
        response.should_receive(:[]).with('commit').and_return('http://tx/42/commit')
        session.should_receive(:resource_url).with('transaction', nil).and_return('http://new.tx')
        HTTParty.should_receive(:post).with('http://new.tx', anything).and_return(response)
        tx = session.begin_tx
        tx.commit_url.should == 'http://tx/42/commit'
        tx.exec_url.should == 'http://tx/42'
        Thread.current[:neo4j_curr_tx].should == tx
      end
    end

    describe 'create_node' do

      before do
        session.stub(:resource_url).and_return("http://resource_url")
      end

      it "create_node() generates 'CREATE (v1) RETURN v1'" do
        session.stub(:resource_url).and_return
        session.should_receive(:_query).with("CREATE (v1) RETURN ID(v1)").and_return(cypher_response)
        session.create_node
      end

      it 'create_node(name: "jimmy") generates ' do
        session.should_receive(:_query).with("CREATE (v1 {name : 'jimmy'}) RETURN v1").and_return(cypher_response)
        session.create_node(name: 'jimmy')
      end

      it 'create_node({}, [:person])' do
        session.should_receive(:_query).with("CREATE (v1:`person`) RETURN v1").and_return(cypher_response)
        session.create_node({}, [:person])
      end

      it "initialize a CypherNode instance" do
        session.should_receive(:_query).with("CREATE (v1) RETURN v1").and_return(cypher_response)
        n = double("cypher node")
        Neo4j::Server::CypherNode.should_receive(:new).and_return(n)
        n.should_receive(:init_resource_data).with  do |node_data, url|
          node_data['self'].should == 'http://localhost:7474/db/data/node/1915'
          url.should == 'http://localhost:7474/db/data/node/1915'
        end

        session.create_node
      end
    end

  end
end
