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
        fail ArgumentError, "Invalid adaptor: #{adaptor.inspect}" if !adaptor.is_a?(Adaptors::Base)

        @adaptor = adaptor

        @adaptor.connect
      end

      %w(
        query
        queries
        start_transaction
        end_transaction
        transactions
      ).each do |method|
        define_method(method) do |*args|
          @adaptor.send(method, *args)
        end
      end
    end
  end
end
