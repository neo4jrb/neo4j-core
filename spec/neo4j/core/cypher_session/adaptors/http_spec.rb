require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'
require './spec/neo4j/core/shared_examples/adaptor'
require './spec/neo4j/core/shared_examples/http'

describe Neo4j::Core::CypherSession::Adaptors::HTTP, new_cypher_session: true do
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

    it 'uses net_http_persistent by default' do
      expect_any_instance_of(Faraday::Connection).to receive(:adapter).with(:net_http_persistent)
      conn = adaptor_class.new(url).connect
    end

    it 'passes the :http_adaptor option to Faraday' do
      expect_any_instance_of(Faraday::Connection).to receive(:adapter).with(:something)
      conn = adaptor_class.new(url, http_adaptor: :something).connect
    end

    (Faraday::Adapter.instance_variable_get(:@registered_middleware).keys - [:test, :rack]).each do |adaptor_name|
      describe "the :#{adaptor_name} adaptor" do
        let(:http_adaptor) { adaptor_name }
        it_behaves_like 'Neo4j::Core::CypherSession::Adaptors::Http'
      end
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

      expect_http_requests(0) do
        adaptor.transaction do
        end
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
      expect(result.to_a[0].r).to eq(labels: 1)

      result = adaptor.query('RETURN {type: 1} AS r')
      expect(result.to_a[0].r).to eq(type: 1)

      result = adaptor.query('RETURN {start: 1} AS r')
      expect(result.to_a[0].r).to eq(start: 1)
    end
  end

  it_behaves_like 'Neo4j::Core::CypherSession::Adaptor'
end
