module Neo4j::Server
  class CypherTransactionRelationship < CypherRelationship
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator
    include Neo4j::Core::ActiveEntity
    attr_reader :_start_node_id, :_end_node_id, :rel_type, :neo_id

    def initialize(session, values, rel_info = {})
      @session = session
      @props = values
      @_start_node_id = rel_info[:from_node_id]
      @_end_node_id   = rel_info[:to_node_id]
      @rel_type     = rel_info[:type]
      @neo_id       = rel_info[:neo_id]
    end

    alias_method :id, :neo_id

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