require 'spec_helper'

describe 'Neo4j::Server::CypherNode#create_rel' do

  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474")
  end

  after(:all) do
    @db.unregister
  end

  it "can create a new relationship" do
    node_a = Neo4j::Node.create(name: 'a')
    node_b = Neo4j::Node.create(name: 'b')
    rel = node_a.create_rel(:best_friend, node_b)
    rel.neo_id.should be_a_kind_of(Fixnum)

    rel.start_node.neo_id.should == node_a.neo_id
    rel.end_node.neo_id.should == node_b.neo_id
  end
end