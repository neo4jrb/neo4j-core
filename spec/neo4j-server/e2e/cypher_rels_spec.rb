require 'spec_helper'

describe 'Neo4j::Server::CypherNode' do

  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474")
  end

  after(:all) do
    @db.unregister
  end

  describe 'create_rel' do
    let(:node_a) { Neo4j::Node.create(name: 'a') }
    let(:node_b) { Neo4j::Node.create(name: 'b') }

    it "can create a new relationship" do
      rel = node_a.create_rel(:best_friend, node_b)
      rel.neo_id.should be_a_kind_of(Fixnum)

      rel.start_node.neo_id.should == node_a.neo_id
      rel.end_node.neo_id.should == node_b.neo_id
    end

    it "can create a new relationship with properties" do
      rel = node_a.create_rel(:best_friend, node_b, since: 2001)
      rel[:since].should == 2001
    end
  end

  describe 'rels' do

  end
end