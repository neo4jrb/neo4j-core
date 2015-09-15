require 'spec_helper'
require 'neo4j/core/cypher_session'

describe Neo4j::Core::CypherSession do
  describe '#initialize' do
    it 'fails with invalid adaptor' do
      expect do
        Neo4j::Core::CypherSession.new(Object.new)
      end.to raise_error ArgumentError, /^Invalid adaptor: /
    end

    it 'takes an Adaptors::Base object' do
      expect do
        Neo4j::Core::CypherSession.new(Neo4j::Core::CypherSession::Adaptors::HTTP.new('url'))
      end.not_to raise_error
    end
  end
end