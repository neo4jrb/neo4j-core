require 'neo4j/core/cypher_session/adaptors/http'

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
        transaction
        transaction_started?

        version

        indexes_for_label
        uniqueness_constraints_for_label
      ).each do |method, &block|
        define_method(method) do |*args, &block|
          @adaptor.send(method, *args, &block)
        end
      end
    end
  end
end
