require 'spec_helper'

module Neo4j::Server
  describe CypherTransaction, api: :server do

    before do
      session || create_server_session
    end

    after do
      session && session.close
      Neo4j::Transaction.current && Neo4j::Transaction.current.finish
    end


    it "can open and commit a transaction" do
      tx = session.begin_tx
      tx.success
      tx.finish
    end

    it "can run a valid query" do
      tx = session.begin_tx
      q = tx._query("START n=node(0) RETURN ID(n)")
      q.response.code.should == 200
      q.response['results'].should == [{"columns"=>["ID(n)"], "data"=>[{"row"=>[0]}]}]
    end


    it "sets the response error fields if not a valid query" do
      tx = session.begin_tx
      r = tx._query("START n=fs(0) RRETURN ID(n)")
      r.error?.should be_true

      r.error_msg.should =~ /Invalid input/
      r.error_status.should =~ /Syntax/
    end

    it 'can commit' do
      tx = session.begin_tx
      tx.success
      response = tx.finish
      response.code.should == 200
    end


    it "can create a node" do
      tx = session.begin_tx
      node = Neo4j::Node.create(name: 'andreas')
      tx.success
      tx.finish.code.should == 200
      node['name'].should == 'andreas'
    end


    it "can update a property" do
      node = Neo4j::Node.create(name: 'foo')
      Neo4j::Transaction.run do
        node[:name] = 'bar'
        node[:name].should == 'bar'
      end
      node[:name].should == 'bar'
    end

    it 'can rollback' do
      node = Neo4j::Node.create(name: 'andreas')
      Neo4j::Transaction.run do |tx|
        node[:name] = 'foo'
        node[:name].should == 'foo'
        tx.failure
      end

      node['name'].should == 'andreas'
    end

    it 'can continue operations after transaction is rolledback' do
      node = Neo4j::Node.create(name: 'andreas')
      Neo4j::Transaction.run do |tx|
        tx.failure
        node[:name] = 'foo'
        node[:name].should == 'foo'
      end
      node['name'].should == 'andreas'

    end

    it "can use Transaction block style" do
      node = Neo4j::Transaction.run do
        Neo4j::Node.create(name: 'andreas')
      end

      node['name'].should == 'andreas'
    end
  end
end
