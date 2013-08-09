require 'spec_helper'

describe Neo4j::Server::CypherRelationship do

  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474")
  end

  after(:all) do
    @db.unregister
  end

  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }

  describe 'create_rel' do

    it "can create a new relationship" do
      rel = node_a.create_rel(:best_friend, node_b)
      rel.neo_id.should be_a_kind_of(Fixnum)
      rel.exist?.should be_true
    end


    it 'has a start_node and end_node' do
      rel = node_a.create_rel(:best_friend, node_b)
      rel.start_node.neo_id.should == node_a.neo_id
      rel.end_node.neo_id.should == node_b.neo_id
    end

    it "can create a new relationship with properties" do
      rel = node_a.create_rel(:best_friend, node_b, since: 2001)
      rel[:since].should == 2001
    end

  end

  describe 'exist?' do
    it 'is true if it exists' do
      rel = node_a.create_rel(:best_friend, node_b)
      rel.exist?.should be_true
    end
  end

  describe '[] and []=' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'can set a relation' do
      rel_a[:since] = 2000
      rel_a[:since].should == 2000
    end

    it 'can delete a relationship' do
      rel_a[:since] = 'hej'
      rel_a[:since] = nil
      rel_a[:since].should be_nil
    end
  end

  describe 'del' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'does not exist after del' do
      rel_a.exist?.should be_true
      rel_a.del
      rel_a.exist?.should be_false
    end
  end

  describe 'rels' do

    it 'returns an empty Enumerable if not relationships' do
      pending
      node_a.rels.to_a.should == []
    end
  end
end