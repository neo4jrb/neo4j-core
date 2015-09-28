require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'
require './spec/neo4j/core/shared_examples/adaptor'

describe Neo4j::Core::CypherSession::Adaptors::HTTP do
  before(:all) { setup_http_request_subscription }
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::HTTP }

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

  describe 'transactions' do
    it 'lets you execute a query in a transaction' do
      expect_http_requests(2) do
        adaptor.start_transaction
        adaptor.query('MATCH n RETURN n LIMIT 1')
        adaptor.end_transaction
      end

      expect_http_requests(2) do
        adaptor.transaction do
          adaptor.query('MATCH n RETURN n LIMIT 1')
        end
      end
    end
  end

  describe 'unwrapping' do
    it 'is not fooled by returned Maps with key expected for nodes/rels/paths' do
      result = adaptor.query('RETURN {labels: 1} AS r')
      expect(result[0].r).to eq(labels: 1)

      result = adaptor.query('RETURN {type: 1} AS r')
      expect(result[0].r).to eq(type: 1)

      result = adaptor.query('RETURN {start: 1} AS r')
      expect(result[0].r).to eq(start: 1)
    end
  end

  it_behaves_like 'Neo4j::Core::CypherSession::Adaptor'
end
