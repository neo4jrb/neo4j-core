require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do

  it_behaves_like "Neo4j::Node auto tx"
  it_behaves_like "Neo4j::Node with tx"

  describe 'transactions' do
    let(:bob)   { Neo4j::Node.create({ name: 'bob' }, :person)  }
    let(:jim)   { Neo4j::Node.create({ name: 'jim' }, :person)  }

    it 'return CypherNodes' do
      begin
        tx = Neo4j::Transaction.new
        expect(bob).to be_a(Neo4j::Server::CypherNode)
        expect(jim).to be_a(Neo4j::Server::CypherNode)
        expect(Neo4j::Label.find_all_nodes(:person)).to include(bob, jim)
        [bob, jim].each { |n| n.del }
      ensure
        tx.close
      end
    end

    it 'return CypherRelationships' do
      begin
        tx = Neo4j::Transaction.new
        r = Neo4j::Relationship.create(:knows, bob, jim, since: 2014)
        expect(r).to be_a(Neo4j::Server::CypherRelationship)
        expect(r['since']).to eq 2014
      ensure
        tx.close
      end
    end
  end
end