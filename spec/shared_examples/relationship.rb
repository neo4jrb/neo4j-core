RSpec.shared_examples 'Neo4j::Relationship' do
  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }
  let(:node_c) { Neo4j::Node.create(name: 'c') }

  describe 'classmethod: load' do
    it 'returns the relationship' do
      rel = node_a.create_rel(:best_friend, node_b)
      id = rel.neo_id
      expect(Neo4j::Relationship.load(id)).to eq(rel)
    end

    it 'returns nil if not found' do
      expect(Neo4j::Relationship.load(4_299_991)).to be_nil
    end
  end

  describe 'classmethod: _load' do
    it 'returns the unwrapped relationship' do
      rel = node_a.create_rel(:best_friends, node_b)
      id = rel.neo_id
      expect(Neo4j::Relationship._load(id)).to eq(rel)
    end

    it 'returns nil if not found' do
      expect(Neo4j::Relationship._load(4_299_991)).to be_nil
    end
  end

  describe 'classmethod: create' do
    it 'creates a relationship' do
      a = Neo4j::Node.create
      b = Neo4j::Node.create
      r = Neo4j::Relationship.create(:knows, a, b)
      expect(r).not_to be_nil
      expect(a.rel(dir: :outgoing, type: :knows)).to eq(r)
      expect(b.rel(dir: :incoming, type: :knows)).to eq(r)
    end

    it 'can create and set properties' do
      a = Neo4j::Node.create
      b = Neo4j::Node.create
      Neo4j::Relationship.create(:knows, a, b, name: 'a', age: 42)
      expect(a.rel(dir: :outgoing, type: :knows)[:name]).to eq('a')
      expect(b.rel(dir: :incoming, type: :knows)[:age]).to eq(42)
    end
  end

  describe 'create_rel' do
    it 'can create relationships with array properties' do
      a = Neo4j::Node.create
      b = Neo4j::Node.create
      a.create_rel('test_rel', b, foo: ['bar'])
      expect(a.rels.to_a.first.props[:foo]).to eq(['bar'])
    end
  end

  describe 'rel_type' do
    it 'returns the type' do
      a = Neo4j::Node.create
      b = Neo4j::Node.create
      rel = a.create_rel(:knows, b)
      expect(rel.rel_type).to be(:knows)
    end
  end

  describe 'exist?' do
    it 'is true if it exists' do
      rel = node_a.create_rel(:best_friend, node_b)
      expect(rel.exist?).to be true
    end
  end

  describe '[] and []=' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'can set a relation' do
      rel_a[:since] = 2000
      expect(rel_a[:since]).to eq(2000)
    end

    it 'can delete a relationship' do
      rel_a[:since] = 'hej'
      rel_a[:since] = nil
      expect(rel_a[:since]).to be_nil
    end
  end

  describe 'end_node' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'returns the end_node' do
      expect(rel_a.end_node).to eq(node_b)
    end
  end

  describe 'other_node' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'returns the other node' do
      expect(rel_a.other_node(node_a)).to eq(node_b)
      expect(rel_a.other_node(node_b)).to eq(node_a)
    end
  end

  describe 'start_node' do
    let(:rel_a) { node_a.create_rel(:best_friend, node_b) }

    it 'returns the end_node' do
      expect(rel_a.start_node).to eq(node_a)
    end
  end

  describe 'del' do
    let(:rel_a) do
      node_a.create_rel(:best_friend, node_b)
    end

    it 'does not exist after del' do
      expect(rel_a.exist?).to be true
      rel_a.del
      expect(rel_a.exist?).to be false
    end

    it 'does not exist after destroy' do
      expect(rel_a.exist?).to be true
      rel_a.destroy
      expect(rel_a.exist?).to be false
    end

    it 'does not exist after delete' do
      expect(rel_a.exist?).to be true
      rel_a.delete
      expect(rel_a.exist?).to be false
    end
  end

  describe 'update_props' do
    let(:n1) { Neo4j::Node.create }
    let(:n2) { Neo4j::Node.create }

    it 'keeps old properties' do
      a = n1.create_rel(:knows, n2, old: 'a')
      a.update_props({})
      expect(a[:old]).to eq('a')

      a.update_props(new: 'b', name: 'foo')
      expect(a[:old]).to eq('a')
      expect(a[:new]).to eq('b')
      expect(a[:name]).to eq('foo')
    end

    it 'replace old properties' do
      a = n1.create_rel(:knows, n2, old: 'a')
      a.update_props(old: 'b')
      expect(a[:old]).to eq('b')
    end

    it 'replace escape properties' do
      a = n1.create_rel(:knows, n2)
      a.update_props(old: "\"'")
      expect(a[:old]).to eq("\"'")
    end

    it 'allows strange property names' do
      a = n1.create_rel(:knows, n2)
      a.update_props('1' => 2, ' ha ' => 'ho')
      expect(a.props).to eq(:'1' => 2, :' ha ' => 'ho')
    end
  end
end
