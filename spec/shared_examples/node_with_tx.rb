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
      node.should_not exist
    end

    it 'rolls back the transaction if an exception occurs' do
      ids = []
      begin
        Neo4j::Transaction.run do |tx|
          a = Neo4j::Node.create
          ids << a.neo_id
          Neo4j::Node.load(ids.first).should == a
          raise "should rollback"
        end
      rescue Exception => e
        e.to_s.should == 'should rollback'
      end
      Neo4j::Node.load(ids.first).should be_nil
    end

    it 'can rollback a property' do
      node = Neo4j::Node.create(name: 'foo')
      Neo4j::Transaction.run do |tx|
        node[:name] = 'bar'
        node[:name].should == 'bar'
        tx.failure
      end
      node[:name].should == 'foo'
    end
  end

  context "inside a transaction" do

    describe 'Neo4j::Node.create' do
      it 'creates a new node' do
        n = Neo4j::Transaction.run do
          Neo4j::Node.create name: 'jimmy'
        end
        n[:name].should == 'jimmy'
      end

      it 'does not have any relationships' do
        Neo4j::Transaction.run do
          n = Neo4j::Node.create
          n.rels.should be_empty
          n
        end.rels.should be_empty
      end
    end

    describe 'create_rel' do
      it 'creates the relationship' do
        rel = Neo4j::Transaction.run do
          node_a = Neo4j::Node.create name: 'a'
          node_b = Neo4j::Node.create name: 'b'
          rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
          node_a.rels.to_a.should == [rel_a]
          rel_a[:age].should == 42
          rel_a
        end
        rel[:age].should == 42
      end

    end
  end

end
