require 'spec_helper'
require 'neo4j/core/cypher_session/adapters/http'
require './spec/neo4j/core/shared_examples/adapter'

describe Neo4j::Core::CypherSession::Adapters::HTTP do
  before(:all) { setup_http_request_subscription }
  let(:adapter_class) { Neo4j::Core::CypherSession::Adapters::HTTP }

  let(:url) { ENV['NEO4J_URL'] }
  let(:adapter) { adapter_class.new(url) }
  subject { adapter }

  describe '#initialize' do
    it 'validates URLs' do
      expect { adapter_class.new('url').connect }.to raise_error ArgumentError, /Invalid URL:/
      expect { adapter_class.new('https://foo@localhost:7474').connect }.not_to raise_error

      expect { adapter_class.new('http://localhost:7474').connect }.not_to raise_error
      expect { adapter_class.new('https://localhost:7474').connect }.not_to raise_error
      expect { adapter_class.new('https://localhost:7474/').connect }.not_to raise_error
      expect { adapter_class.new('https://foo:bar@localhost:7474').connect }.not_to raise_error
      expect { adapter_class.new('bolt://localhost:7474').connect }.to raise_error ArgumentError, /Invalid URL/
      expect { adapter_class.new('foo://localhost:7474').connect }.to raise_error ArgumentError, /Invalid URL/
    end
  end

  let(:session_double) { double('session', adapter: subject) }

  before do
    adapter.connect
    adapter.query(session_double, 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
  end

  describe 'transactions' do
    it 'lets you execute a query in a transaction' do
      expect_http_requests(2) do
        tx = subject.transaction(session_double)
        tx.query('MATCH (n) RETURN n LIMIT 1')
        tx.close
      end
    end
  end

  context 'when connected' do
    before { subject.connect }

    describe 'transactions' do
      it 'lets you execute a query in a transaction' do
        expect_http_requests(2) do
          tx = subject.transaction(session_double)
          tx.query('MATCH (n) RETURN n LIMIT 1')
          tx.close
        end

        expect_http_requests(2) do
          subject.transaction(session_double) do |tx|
            tx.query('MATCH (n) RETURN n LIMIT 1')
          end
        end
      end
    end

    describe 'unwrapping' do
      it 'is not fooled by returned Maps with key expected for nodes/rels/paths' do
        result = subject.query(session_double, 'RETURN {labels: 1} AS r')
        expect(result.to_a[0].r).to eq(labels: 1)

        result = subject.query(session_double, 'RETURN {type: 1} AS r')
        expect(result.to_a[0].r).to eq(type: 1)

        result = subject.query(session_double, 'RETURN {start: 1} AS r')
        expect(result.to_a[0].r).to eq(start: 1)
      end
    end
  end

  it_behaves_like 'Neo4j::Core::CypherSession::Adapter'
end
