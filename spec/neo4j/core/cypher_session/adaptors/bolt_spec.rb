require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/bolt'
require './spec/neo4j/core/shared_examples/adaptor'

describe Neo4j::Core::CypherSession::Adaptors::Bolt, new_cypher_session: true do
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::Bolt }
  let(:url) { ENV['NEO4J_BOLT_URL'] }

  subject { adaptor_class.new(url, logger_level: Logger::DEBUG) }

  describe '#initialize' do
    let_context(url: 'url') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: :symbol) { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 123) { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: 'http://localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'http://foo:bar@localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'https://localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }
    let_context(url: 'https://foo:bar@localhost:7687') { subject_should_raise ArgumentError, /Invalid URL/ }

    let_context(url: 'bolt://foo@localhost:') { subject_should_not_raise }
    let_context(url: 'bolt://:foo@localhost:7687') { subject_should_not_raise }

    let_context(url: 'bolt://localhost:7687') { subject_should_not_raise }
    let_context(url: 'bolt://foo:bar@localhost:7687') { subject_should_not_raise }
  end

  describe 'connecting' do
    # before { adaptor.connect }

    # describe 'transactions' do
    #   it 'lets you execute a query in a transaction' do
    #     expect_http_requests(2) do
    #       adaptor.start_transaction
    #       adaptor.query('MATCH n RETURN n LIMIT 1')
    #       adaptor.end_transaction
    #     end

    #     expect_http_requests(0) do
    #       adaptor.transaction do
    #       end
    #     end

    #     expect_http_requests(2) do
    #       adaptor.transaction do
    #         adaptor.query('MATCH n RETURN n LIMIT 1')
    #       end
    #     end
    #   end
    # end

    # describe 'unwrapping' do
    #   it 'is not fooled by returned Maps with key expected for nodes/rels/paths' do
    #     result = adaptor.query('RETURN {labels: 1} AS r')
    #     expect(result.to_a[0].r).to eq(labels: 1)

    #     result = adaptor.query('RETURN {type: 1} AS r')
    #     expect(result.to_a[0].r).to eq(type: 1)

    #     result = adaptor.query('RETURN {start: 1} AS r')
    #     expect(result.to_a[0].r).to eq(start: 1)
    #   end
    # end
  end

  it_behaves_like 'Neo4j::Core::CypherSession::Adaptor'
end
