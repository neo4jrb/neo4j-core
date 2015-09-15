require 'neo4j/core/cypher_session/adaptors/http'

# TODOs:
# Execute cypher queries
# Execute cypher queries as a batch
# Transactions
# Returns nodes, relationships, and paths

module Neo4j
  module Core
    class CypherSession
      def initialize(adaptor)
        raise ArgumentError, "Invalid adaptor: #{adaptor.inspect}" if !adaptor.is_a?(Adaptors::Base)

        @adaptor = adaptor

        @adaptor.connect
      end

      def query(query_string, parameters = {})
        @adaptor.query(query_string, parameters)
      end
    end
  end
end
