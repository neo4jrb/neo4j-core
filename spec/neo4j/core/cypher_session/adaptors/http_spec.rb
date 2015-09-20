require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'

describe Neo4j::Core::CypherSession::Adaptors::HTTP do
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::HTTP }

  before(:all) { setup_query_subscription(Neo4j::Core::CypherSession::Adaptors::HTTP) }

  describe '#initialize' do
    it 'validates URLs' do
      expect { adaptor_class.new('url') }.to raise_error ArgumentError, /Invalid URL:/
      expect { adaptor_class.new('https://foo@localhost:7474') }.not_to raise_error

      expect { adaptor_class.new('http://localhost:7474') }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474') }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474/') }.not_to raise_error
      expect { adaptor_class.new('https://foo:bar@localhost:7474') }.not_to raise_error
    end
  end

  let(:url) { ENV['NEO4J_URL'] }
  let(:adaptor) { adaptor_class.new(url) }

  before { adaptor.connect }

  describe '#query' do
    it 'Can make a query' do
      adaptor.query('MERGE path=n-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end
  end

  describe 'transactions' do
    it 'lets you execute a query in a transaction' do
      expect_queries(2) do
        adaptor.start_transaction
        adaptor.query('MATCH n RETURN n LIMIT 1')
        adaptor.end_transaction
      end

      expect_queries(2) do
        adaptor.transaction do
          adaptor.query('MATCH n RETURN n LIMIT 1')
        end
      end
    end

    it 'does not allow transactions in the wrong order' do
      expect { adaptor.end_transaction }.to raise_error(RuntimeError, /Cannot close transaction without starting one/)
    end
  end

  describe 'results' do
    it 'handles array results' do
      result = adaptor.query("CREATE (a {b: 'c'}) RETURN [a]")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:'[a]']).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:'[a]'].properties).to eq(b: 'c')
    end

    it 'symbolizes keys for Neo4j objects' do
      result = adaptor.query('RETURN {a: 1} AS obj')

      expect(result.hashes).to eq([{obj: {a: 1}}])

      structs = result.structs
      expect(structs).to be_a(Array)
      expect(structs.size).to be(1)
      expect(structs[0].obj).to eq(a: 1)
    end
  end
end
