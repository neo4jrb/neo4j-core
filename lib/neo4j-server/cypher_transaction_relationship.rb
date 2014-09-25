module Neo4j::Server
  class CypherTransactionRelationship < Neo4j::Relationship
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator
    include Neo4j::Core::ActiveEntity

    def initialize(session, values)
      @session = session
      @props = values
    end

    def props
      @props
    end

    def delegator=(node)
      @delegator = self
    end

    def delegator
      @delegator || (raise 'unset delegator')
    end

    def transaction_rel?
      true
    end

    private

    class << self
      def rebuild(session, values)
        node = CypherTransactionRelationship.new(session, values).wrapper
      end
    end
  end
end