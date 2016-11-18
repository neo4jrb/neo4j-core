module Neo4j
  module Core
    class CypherSession
      attr_reader :adapter

      def initialize(adapter)
        fail ArgumentError, "Invalid adapter: #{adapter.inspect}" if !adapter.is_a?(Adapters::Base)

        @adapter = adapter

        @adapter.connect
      end

      def transaction_class
        Neo4j::Core::CypherSession::Transactions::Base
      end

      %w(
        version
      ).each do |method, &_block|
        define_method(method) do |*args, &block|
          @adapter.send(method, *args, &block)
        end
      end

      %w(
        query
        queries

        transaction

        indexes
        constraints
      ).each do |method, &_block|
        define_method(method) do |*args, &block|
          @adapter.send(method, self, *args, &block)
        end
      end
    end
  end
end
