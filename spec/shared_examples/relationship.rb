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

  describe 'classmethod: create' do
    it 'creates a relationship' do
      a = Neo4j::Node.create
      b = Neo4j::Node.create
      r = Neo4j::Relationship.create(:knows, a, b)
      r.should_not be_nil
      a.rel(dir: :outgoing, type: :knows).should eq(r)
      b.rel(dir: :incoming, type: :knows).should eq(r)
    end

    it 'can create and set properties' do
      a = Neo4j::Node.create
      b = Neo4j::Node.create
      r = Neo4j::Relationship.create(:knows, a, b, {name: 'a', age: 42})
      a.rel(dir: :outgoing, type: :knows)[:name].should eq('a')
      b.rel(dir: :incoming, type: :knows)[:age].should eq(42)

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

  describe 'end_node' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'returns the end_node' do
      rel_a.end_node.should == node_b
    end

  end

  describe 'other_node' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'returns the other node' do
      rel_a.other_node(node_a).should == node_b
      rel_a.other_node(node_b).should == node_a
    end

  end

  describe 'start_node' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'returns the end_node' do
      rel_a.start_node.should == node_a
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

  describe 'update_props' do
    let(:n1) { Neo4j::Node.create }
    let(:n2) { Neo4j::Node.create }

    it 'keeps old properties' do
      a = n1.create_rel(:knows, n2, {old: 'a'})
      a.update_props({})
      a[:old].should == 'a'

      a.update_props({new: 'b', name: 'foo'})
      a[:old].should == 'a'
      a[:new].should == 'b'
      a[:name].should == 'foo'
    end

    it 'replace old properties' do
      a = n1.create_rel(:knows, n2, old: 'a')
      a.update_props({old: 'b'})
      a[:old].should == 'b'
    end

    it 'replace escape properties' do
      a = n1.create_rel(:knows, n2)
      a.update_props(old: "\"'")
      a[:old].should == "\"'"
    end

    it 'allows strange property names' do
      a = n1.create_rel(:knows, n2)
      a.update_props({"1" => 2, " ha " => "ho"})
      a.props.should == {:"1"=>2, :" ha "=>"ho"}
    end

  end

end