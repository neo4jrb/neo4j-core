RSpec.shared_examples 'Neo4j::Node with tx' do
  shared_examples 'a node with properties and id' do
    describe '#neo_id' do
      it 'is a fixnum' do
        expect(subject.neo_id).to be_a(Fixnum)
      end
    end

    describe '#props' do
      it 'contains a hash of properties' do
        expect(subject.props).to eq(name: 'Brian', hat: 'fancy')
      end
    end

    describe '#rels' do
      it 'does not have any relationships' do
        expect(subject.rels).to be_empty
      end
    end

    describe '#create_rel' do
      it 'creates the relationship' do
        other_node = Neo4j::Node.create name: 'a'
        rel_a = subject.create_rel(:best_friend, other_node, age: 42)
        expect(subject.rels.to_a).to eq([rel_a])
        expect(rel_a[:age]).to eq(42)
      end
    end
  end

  context 'inside a transaction' do
    describe 'Neo4j::Relationship.create' do
      subject(:created_rel) do
        @node_a = Neo4j::Node.create
        @node_b = Neo4j::Node.create
        Neo4j::Relationship.create(:knows, @node_a, @node_b, since: 1992)
      end

      around(:example) do |example|
        tx = Neo4j::Transaction.new
        example.run
        tx.close
      end

      describe '#exist' do
        specify { is_expected.to exist }
      end

      it 'has properties' do
        expect(subject.props).to eq(since: 1992)
      end
    end

    describe 'Neo4j::Node.create' do
      around(:example) do |example|
        tx = Neo4j::Transaction.new
        example.run
        tx.close
      end

      subject(:created_node) do
        Neo4j::Node.create({name: 'Brian', hat: 'fancy'}, :person)
      end

      it_behaves_like 'a node with properties and id'

      describe 'Neo4j::Node.load' do
        subject(:loaded_node) do
          Neo4j::Node.load(created_node.neo_id)
        end

        it_behaves_like 'a node with properties and id'
      end
    end
  end

  context 'nested transaction' do
    it 'can create and load nodes in nested tx' do
      n = Neo4j::Transaction.run do
        n1 = Neo4j::Transaction.run do
          n2 = Neo4j::Node.create
          expect(Neo4j::Node.load(n2.neo_id)).to eq n2
          n2
        end
        expect(Neo4j::Node.load(n1.neo_id)).to eq n1
        n1
      end
      expect(Neo4j::Node.load(n.neo_id)).to eq n
    end

    it 'can rollback inner transaction' do
      id = Neo4j::Transaction.run do
        Neo4j::Transaction.run do |tx|
          i = Neo4j::Node.create.neo_id
          tx.failure
          i
        end
      end
      expect(Neo4j::Node.load(id)).to eq(nil)
    end

    it 'can rollback outer transaction' do
      id = Neo4j::Transaction.run do  |tx|
        i = Neo4j::Transaction.run do
          Neo4j::Node.create.neo_id
        end
        tx.failure
        i
      end
      expect(Neo4j::Node.load(id)).to eq(nil)
    end
  end

  context 'rollback' do
    it 'does not rolls back the transaction if no failure' do
      node = Neo4j::Transaction.run do
        Neo4j::Node.create
      end
      expect(node).to exist
    end

    it 'rolls back the transaction if failure is called' do
      node = Neo4j::Transaction.run do |tx|
        a = Neo4j::Node.create
        tx.failure
        a
      end
      expect(node).not_to exist
    end

    it 'rolls back the transaction if an exception occurs' do
      ids = []
      expect do
        Neo4j::Transaction.run do |tx|
          a = Neo4j::Node.create
          ids << a.neo_id
          expect(Neo4j::Node.load(ids.first)).to eq(a)
          fail 'should rollback'
        end
      end.to raise_error('should rollback')

      expect(Neo4j::Node.load(ids.first)).to be_nil
    end

    it 'can rollback a property' do
      node = Neo4j::Node.create(name: 'foo')
      Neo4j::Transaction.run do |tx|
        node[:name] = 'bar'
        expect(node[:name]).to eq('bar')
        tx.failure
      end
      expect(node[:name]).to eq('foo')
    end

    it 'can rollback a relationship' do
      node1 = Neo4j::Node.create(name: 'node1')
      node2 = Neo4j::Node.create(name: 'node2')
      expect(node1.node(dir: :outgoing, type: :knows)).to be_nil

      Neo4j::Transaction.run do |tx|
        node1.create_rel(:knows, node2)
        expect(node1.node(dir: :outgoing, type: :knows)).to eq(node2)
        tx.failure
      end

      expect(node1.node(dir: :outgoing, type: :knows)).to be_nil
    end
  end
end
