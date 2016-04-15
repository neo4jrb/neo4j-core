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
        query
        queries

        transaction

        version
        indexes_for_label
        uniqueness_constraints_for_label
      ).each do |method, &_block|
        define_method(method) do |*args, &block|
          if %w(query queries transaction).include?(method)
            @adaptor.send(method, self, *args, &block)
          else
            @adaptor.send(method, *args, &block)
          end
        end
      end
    end
  end
end
