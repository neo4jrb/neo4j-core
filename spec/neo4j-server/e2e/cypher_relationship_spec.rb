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
  let(:node_c) { Neo4j::Node.create(name: 'c') }

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

    describe 'rels()' do
      it 'finds relationship of any dir and any type' do
        rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
        rel_b = node_b.create_rel(:work, node_a)
        node_a.rels.to_a.should =~ [rel_a, rel_b]
      end

      it "returns an empty enumerable if there are no relationships" do
        node_a.rels.should be_empty
      end
    end

    describe 'rels(type: :work)' do
      it 'finds any dir of one relationship type' do
        rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
        rel_b = node_b.create_rel(:work, node_a)
        node_a.rels(type: :work).to_a.should == [rel_b]
        node_a.rels(type: :best_friend).to_a.should == [rel_a]
      end
    end

    describe 'rels(dir: outgoing)' do
      it 'finds outgoing rels of any type' do
        rel_a = node_a.create_rel(:best_friend, node_b)
        rel_b = node_b.create_rel(:work, node_a)
        node_a.rels(dir: :outgoing).to_a.should == [rel_a]
        node_b.rels(dir: :outgoing).to_a.should == [rel_b]
      end
    end

    describe 'rels(dir: incoming)' do
      it 'finds incoming rels of any type' do
        rel_a = node_a.create_rel(:best_friend, node_b)
        rel_b = node_b.create_rel(:work, node_a)
        node_a.rels(dir: :incoming).to_a.should == [rel_b]
        node_b.rels(dir: :incoming).to_a.should == [rel_a]
      end
    end

    describe 'rels(dir: incoming, type: work)' do
      it 'finds incoming rels of any type' do
        rel_a = node_a.create_rel(:best_friend, node_b)
        rel_b = node_b.create_rel(:work, node_a)
        rel_c = node_a.create_rel(:work, node_b)
        rel_d = node_b.create_rel(:best_friend, node_a)

        node_a.rels(dir: :incoming, type: :work).to_a.should == [rel_b]
        node_a.rels(dir: :outgoing, type: :work).to_a.should == [rel_c]
      end
    end

    describe 'rels(between: node_b)' do
      it 'finds all relationships between two nodes' do
        rel_a = node_a.create_rel(:work, node_b)
        rel_b = node_a.create_rel(:work, node_c)
        node_a.rels(between: node_b).to_a.should == [rel_a]
        node_a.rels(between: node_c).to_a.should == [rel_b]
      end
    end

  end
end