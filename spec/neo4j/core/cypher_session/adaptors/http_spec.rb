require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'
require './spec/neo4j/core/shared_examples/adaptor'

describe Neo4j::Core::CypherSession::Adaptors::HTTP do
  before(:all) { setup_http_request_subscription }
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::HTTP }

  let(:url) { ENV['NEO4J_URL'] }
  let(:adaptor) { adaptor_class.new(url) }
  subject { adaptor }

  describe '#initialize' do
    it 'validates URLs' do
      expect { adaptor_class.new('url').connect }.to raise_error ArgumentError, /Invalid URL:/
      expect { adaptor_class.new('https://foo@localhost:7474').connect }.not_to raise_error

      expect { adaptor_class.new('http://localhost:7474').connect }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474').connect }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474/').connect }.not_to raise_error
      expect { adaptor_class.new('https://foo:bar@localhost:7474').connect }.not_to raise_error
      expect { adaptor_class.new('bolt://localhost:7474').connect }.to raise_error ArgumentError, /Invalid URL/
      expect { adaptor_class.new('foo://localhost:7474').connect }.to raise_error ArgumentError, /Invalid URL/
    end
  end

  describe '#supports_metadata?' do
    it 'supports in version 3.4.0' do
      expect(adaptor).to receive(:version).and_return('3.4.0')
      expect(adaptor.supports_metadata?).to be true
    end

    it 'does not supports in version 2.0.0' do
      expect(adaptor).to receive(:version).and_return('2.0.0')
      expect(adaptor.supports_metadata?).to be false
    end
  end

  let(:session_double) { double('session', adaptor: subject) }

  before do
    adaptor.connect
    adaptor.query(session_double, 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
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

  it_behaves_like 'Neo4j::Core::CypherSession::Adaptor'
end
