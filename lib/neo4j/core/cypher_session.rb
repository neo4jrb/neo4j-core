module Neo4j
  module Core
    class CypherSession
      attr_reader :adaptor

      def initialize(adaptor)
        fail ArgumentError, "Invalid adaptor: #{adaptor.inspect}" if !adaptor.is_a?(Adaptors::Base)

        @adaptor = adaptor

        @adaptor.connect
      end

      def transaction_class
        Neo4j::Core::CypherSession::Transactions::Base
      end

      %w(
        version
      ).each do |method, &_block|
        define_method(method) do |*args, &block|
          @adaptor.send(method, *args, &block)
        end
      end

      %w(
        query
        queries

        transaction

        indexes_for_label
        all_indexes

        uniqueness_constraints_for_label
        all_uniqueness_constraints
      ).each do |method, &_block|
        define_method(method) do |*args, &block|
          @adaptor.send(method, self, *args, &block)
        end
      end

    end
  end
end
