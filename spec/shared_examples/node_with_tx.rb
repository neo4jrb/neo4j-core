RSpec.shared_examples "Neo4j::Node with tx" do
  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }
  let(:node_c) { Neo4j::Node.create(name: 'c') }

  context 'rollback' do
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
      begin
        Neo4j::Transaction.run do |tx|
          a = Neo4j::Node.create
          ids << a.neo_id
          expect(Neo4j::Node.load(ids.first)).to eq(a)
          raise "should rollback"
        end
      rescue Exception => e
        expect(e.to_s).to eq('should rollback')
      end
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
  end

  context "inside a transaction" do

    describe 'Neo4j::Node.create' do
      it 'creates a new node' do
        n = Neo4j::Transaction.run do
          Neo4j::Node.create name: 'jimmy'
        end
        expect(n[:name]).to eq('jimmy')
      end

      it 'does not have any relationships' do
        expect(Neo4j::Transaction.run do
          n = Neo4j::Node.create
          expect(n.rels).to be_empty
          n
        end.rels).to be_empty
      end
    end

    describe 'create_rel' do
      it 'creates the relationship' do
        rel = Neo4j::Transaction.run do
          node_a = Neo4j::Node.create name: 'a'
          node_b = Neo4j::Node.create name: 'b'
          rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
          expect(node_a.rels.to_a).to eq([rel_a])
          expect(rel_a[:age]).to eq(42)
          rel_a
        end
        expect(rel[:age]).to eq(42)
      end

    end
  end

end
