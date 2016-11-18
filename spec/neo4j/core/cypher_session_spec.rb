require 'spec_helper'
require 'neo4j/core/cypher_session'

describe Neo4j::Core::CypherSession do
  describe '#initialize' do
    it 'fails with invalid adapter' do
      expect do
        Neo4j::Core::CypherSession.new(Object.new)
      end.to raise_error ArgumentError, /^Invalid adapter: /
    end

    it 'takes an Adapters::Base object' do
      expect do
        http_adapter = Neo4j::Core::CypherSession::Adapters::HTTP.new(ENV['NEO4J_URL'])
        Neo4j::Core::CypherSession.new(http_adapter)
      end.not_to raise_error
    end
  end
end
