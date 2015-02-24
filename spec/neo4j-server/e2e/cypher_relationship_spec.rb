require 'spec_helper'

describe Neo4j::Server::CypherRelationship, api: :server do
  it_behaves_like 'Neo4j::Relationship'

  describe 'transactions' do
    let(:bob) { Neo4j::Node.create({name: 'bob'}, :person) }
    let(:jim) { Neo4j::Node.create({name: 'jim'}, :person) }

    it 'return CypherRelationships' do
      begin
        tx = Neo4j::Transaction.new
        r = Neo4j::Relationship.create(:knows, bob, jim, since: 2014)
        expect(r).to be_a(Neo4j::Server::CypherRelationship)
        expect(r['since']).to eq 2014
        expect(r[:since]).to eq 2014
      ensure
        tx.close
      end
    end

    context 'existing rels' do
      let!(:r) { Neo4j::Relationship.create(:knows, bob, jim, since: 2014) }

      it 'can load' do
        begin
          tx = Neo4j::Transaction.new
          rel = Neo4j::Relationship.load(r.neo_id)
          expect(rel).to be_a(Neo4j::Server::CypherRelationship)
          expect(rel['since']).to eq 2014
          expect(rel[:since]).to eq 2014
        ensure
          tx.close
        end
      end

      it 'has an id' do
        begin
          tx = Neo4j::Transaction.new
          expect(r.id).not_to be_nil
          expect(r.inspect).to include(r.id.to_s)
        ensure
          tx.close
        end
      end

      it 'can set props' do
        begin
          tx = Neo4j::Transaction.new
          r.props = {since: 1999, end_date: 2065}
          rel = Neo4j::Relationship.load(r.id)
          expect(rel['end_date']).to eq 2065
          expect(rel[:end_date]).to eq 2065
        ensure
          tx.close
        end
      end
    end
  end
end
