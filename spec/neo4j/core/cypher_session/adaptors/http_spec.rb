require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'
require './spec/neo4j/core/shared_examples/adaptor'
require './spec/neo4j/core/shared_examples/http'

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

    describe 'the faraday_options param' do
      describe 'the adapter option' do
        it 'uses net_http_persistent by default' do
          expect_any_instance_of(Faraday::Connection).to receive(:adapter).with(:net_http_persistent)
          adaptor_class.new(url).connect
        end

        it 'will pass through a symbol key' do
          expect_any_instance_of(Faraday::Connection).to receive(:adapter).with(:something)
          adaptor_class.new(url, faraday_options: {adapter: :something}).connect
        end

        it 'will pass through a string key' do
          expect_any_instance_of(Faraday::Connection).to receive(:adapter).with(:something)
          adaptor_class.new(url, 'faraday_options' => {'adapter' => :something}).connect
        end

        adaptors = Faraday::Adapter.instance_variable_get(:@registered_middleware).keys - [:test, :rack]
        adaptors -= [:patron, :em_synchrony, :em_http] if RUBY_PLATFORM == 'java'
        adaptors.each do |adapter_name|
          describe "the :#{adapter_name} adapter" do
            let(:http_adapter) { adapter_name }
            it_behaves_like 'Neo4j::Core::CypherSession::Adaptors::Http'
          end
        end
      end
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
