module Neo4j::Server
  class CypherTransactionNode < Neo4j::Node
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator
    include Neo4j::Core::ActiveEntity

    def initialize(session, values)
      @session = session
      @props = values
    end

    def delegator=(node)
      @delegator = node
    end

    def delegator
      @delegator || (raise 'not implemented')
    end

    def props
      @props
    end

    def labels
      @labels ||= delegator.class.query_as(:result).return("LABELS(result) as result_labels").first.result_labels.map(&:to_sym)
    end

    def transaction_node?
      true
    end

    def exist?
      result = self_query.return("COUNT(result) as result_count")
      result.first.result_count == 1
    end

    def inspect
      "CypherTransactionNode #{id_property_name}: #{delegator.id} (#{object_id})"
    end

    def id_property_name
      delegator.class.id_property_name
    end

    def id
      delegator.id
    end

    def neo_id
      @neo_id ||= self_query.return("ID(result) as result_id").first.result_id
    end

    private

    def self_query
      delegator.class.query_as(:result).where("result.#{id_property_name} = {node_id}").params(node_id: id)
    end
  end
end