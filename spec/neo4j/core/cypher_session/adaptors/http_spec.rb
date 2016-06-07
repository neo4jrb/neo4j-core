require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'
require './spec/neo4j/core/shared_examples/adaptor'

describe Neo4j::Core::CypherSession::Adaptors::HTTP, new_cypher_session: true do
  before(:all) { setup_http_request_subscription }
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::HTTP }

  let(:url) { ENV['NEO4J_URL'] }
  subject { adaptor_class.new(url) }

  describe '#initialize' do
    it 'validates URLs' do
      expect { adaptor_class.new('url').connect }.to raise_error ArgumentError, /Invalid URL:/
      expect { adaptor_class.new('https://foo@localhost:7474').connect }.not_to raise_error

      expect { adaptor_class.new('http://localhost:7474').connect }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474').connect }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474/').connect }.not_to raise_error
      expect { adaptor_class.new('https://foo:bar@localhost:7474').connect }.not_to raise_error
    end
  end

    let_context(url: 'bolt://localhost:7474') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'foo://localhost:7474') { subject_should_raise ArgumentError, /Invalid URL/ }

  let(:session_double) { double('session') }

  before do
    adaptor.connect
    adaptor.query(session_double, 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
  end

  describe 'transactions' do
    it 'lets you execute a query in a transaction' do
      expect_http_requests(2) do
        tx = adaptor.transaction
        tx.query('MATCH (n) RETURN n LIMIT 1')
        tx.close
      end

    let_context(url: 'http://localhost:7474/') { subject_should_not_raise }
    let_context(url: 'https://localhost:7474/') { subject_should_not_raise }
  end

  context 'when connected' do
    before { subject.connect }

    describe 'transactions' do
      it 'lets you execute a query in a transaction' do
        expect_http_requests(2) do
          subject.start_transaction
          subject.query('MATCH (n) RETURN n LIMIT 1')
          subject.end_transaction
        end

      expect_http_requests(2) do
        adaptor.transaction do |tx|
          tx.query('MATCH (n) RETURN n LIMIT 1')
        end
      end
    end

    describe 'unwrapping' do
      it 'is not fooled by returned Maps with key expected for nodes/rels/paths' do
        result = subject.query('RETURN {labels: 1} AS r')
        expect(result.to_a[0].r).to eq(labels: 1)

        result = subject.query('RETURN {type: 1} AS r')
        expect(result.to_a[0].r).to eq(type: 1)

        result = subject.query('RETURN {start: 1} AS r')
        expect(result.to_a[0].r).to eq(start: 1)
      end
    end
  end

  it_behaves_like 'Neo4j::Core::CypherSession::Adaptor'
end
