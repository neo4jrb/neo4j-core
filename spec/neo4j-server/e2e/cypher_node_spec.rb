require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do

  shared_examples 'a node with properties and id' do
    describe '#neo_id' do
      it 'is a fixnum' do
        expect(subject.neo_id).to be_a(Fixnum)
      end
    end

    describe '#props' do
      it 'contains a hash of properties' do
        expect(subject.props).to eq({name: 'Brian', hat: 'fancy'})
      end
    end
  end

  context 'with tx' do
    describe 'Neo4j::Node.create' do

      around(:example) do |example|
        tx = Neo4j::Transaction.new
        example.run
        tx.finish
      end

      subject(:created_node) do
        Neo4j::Node.create({name: 'Brian', hat: 'fancy'}, :person)
      end

      it_behaves_like "a node with properties and id"

      describe 'Neo4j::Node.load' do
        subject(:loaded_node) do
          Neo4j::Node.load(created_node.neo_id)
        end

        it_behaves_like "a node with properties and id"
      end

    end
  end

  context 'without tx' do
    describe 'Neo4j::Node.create' do
      subject(:created_node) do
        Neo4j::Node.create({name: 'Brian', hat: 'fancy'}, :person)
      end

      it_behaves_like "a node with properties and id"

      describe 'Neo4j::Node.load' do
        subject(:loaded_node) do
          Neo4j::Node.load(created_node.neo_id)
        end

        it_behaves_like "a node with properties and id"
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

  it_behaves_like "Neo4j::Node auto tx"
  it_behaves_like "Neo4j::Node with tx"

end
