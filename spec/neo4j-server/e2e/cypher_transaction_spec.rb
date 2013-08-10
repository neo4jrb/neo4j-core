require 'spec_helper'

describe Neo4j::Server::CypherTransaction do
  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474")
  end

  after(:all) do
    @db.unregister
  end

  after do
    Neo4j::Server::CypherTransaction.clear_current
  end

  it "can open and commit a transaction" do
    tx = @db.begin_tx
    tx.success
    tx.finish
  end

  it "can create a query and commit" do
    tx = @db.begin_tx
    q = tx._query("START n=node(0) RETURN n")
    q.code.should == 200
    tx.success
    tx.finish.code.should == 200
  end

  it "can create a node" do
    tx = @db.begin_tx
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