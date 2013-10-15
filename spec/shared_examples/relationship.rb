share_examples_for "Neo4j::Relationship" do

  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }
  let(:node_c) { Neo4j::Node.create(name: 'c') }

  describe 'classmethod: load' do
    it "returns the relationship" do
      rel = node_a.create_rel(:best_friend, node_b)
      id = rel.neo_id
      Neo4j::Relationship.load(id).should == rel
    end

    it 'returns nil if not found' do
      Neo4j::Relationship.load(4299991).should be_nil
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

end