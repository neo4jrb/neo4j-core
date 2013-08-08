require 'spec_helper'

describe Neo4j::Server::CypherTransaction do
  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474")
  end

  after(:all) do
    @db.unregister
  end


  it "can open and commit an transaction" do
    tx = @db.begin_tx
    tx.success
    tx.finish
  end

  it "can open create a query and commit" do
    tx = @db.begin_tx
    q = tx._query("START n=node(0) RETURN n")
    q.response.code.should == '200'
    tx.success
    tx.finish.code.should == 200
  end
end