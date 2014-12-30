require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do
  it_behaves_like 'Neo4j::Node auto tx'
  it_behaves_like 'Neo4j::Node with tx'

  describe 'transactions' do
    around(:each) do |example|
      begin
        Neo4j::Transaction.run do
          example.run
        end
      rescue RuntimeError
      end
    end

    it_behaves_like 'Neo4j::Node auto tx'

    let!(:bob)   { Neo4j::Node.create({name: 'bob'}, :person)  }
    let!(:jim)   { Neo4j::Node.create({name: 'jim'}, :person)  }

    it 'return CypherNodes' do
      begin
        tx = Neo4j::Transaction.new
        expect(bob).to be_a(Neo4j::Server::CypherNode)
        expect(jim).to be_a(Neo4j::Server::CypherNode)
        expect(Neo4j::Label.find_all_nodes(:person)).to include(bob, jim)
      ensure
        tx.close
      end
    end

    it 'can load' do
      begin
        tx = Neo4j::Transaction.new
        node = Neo4j::Node.load(bob.neo_id)
        expect(node).to be_a(Neo4j::Server::CypherNode)
      ensure
        tx.close
      end
    end
  end
end
