require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'
require './spec/neo4j/core/shared_examples/adaptor'

describe Neo4j::Core::CypherSession::Adaptors::HTTP, new_cypher_session: true do
  before(:all) { setup_http_request_subscription }
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::HTTP }

  let(:url) { ENV['NEO4J_URL'] }
  subject { adaptor_class.new(url) }

  describe '#initialize' do
    let_context(url: 'url') { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: 'bolt://localhost:7474') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'foo://localhost:7474') { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: 'http://:bar@localhost:7474') { subject_should_not_raise }
    let_context(url: 'https://:bar@localhost:7474') { subject_should_not_raise }

    let_context(url: 'http://:bar@localhost:') { subject_should_not_raise }
    let_context(url: 'https://:bar@localhost:') { subject_should_not_raise }

    let_context(url: 'http://localhost:7474') { subject_should_not_raise }
    let_context(url: 'https://localhost:7474') { subject_should_not_raise }
    let_context(url: 'https://localhost:7474/') { subject_should_not_raise }

    let_context(url: 'http://foo@localhost:7474') { subject_should_not_raise }
    let_context(url: 'https://foo@localhost:7474') { subject_should_not_raise }
    let_context(url: 'http://foo:bar@localhost:7474') { subject_should_not_raise }
    let_context(url: 'https://foo:bar@localhost:7474') { subject_should_not_raise }

    let_context(url: 'http://localhost:7474/') { subject_should_not_raise }
    let_context(url: 'https://localhost:7474/') { subject_should_not_raise }
  end

  context 'when connected' do
    before { subject.connect }

    describe 'transactions' do
      it 'lets you execute a query in a transaction' do
        expect_http_requests(2) do
          subject.start_transaction
          subject.query('MATCH n RETURN n LIMIT 1')
          subject.end_transaction
        end

        expect_http_requests(0) do
          subject.transaction do
          end
        end

        expect_http_requests(2) do
          subject.transaction do
            subject.query('MATCH n RETURN n LIMIT 1')
          end
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
