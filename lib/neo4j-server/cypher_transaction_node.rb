module Neo4j::Server
  class CypherTransactionNode < CypherNode
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator
    include Neo4j::Core::ActiveEntity

    def initialize(session, values, neo_id)
      @session = session
      @props = values
      @neo_id = neo_id
    end

    def neo_id
      @neo_id ||= self_query.return("ID(result) as result_id").first.result_id
    end

    def inspect
      "CypherTransactionNode #{neo_id} (#{object_id})"
    end
  end
end