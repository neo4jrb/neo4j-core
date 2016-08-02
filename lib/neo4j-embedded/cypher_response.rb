module Neo4j
  module Embedded
    # Wraps the Cypher query result.
    # Loads the node and relationships wrapper if possible and use symbol as column keys.
    # This is typically used in the native neo4j bindings since result does is not a Ruby enumerable with symbols as keys.
    # @note The result is a once forward read only Enumerable, work if you need to read the result twice - use #to_a
    #
    class ResultWrapper
      class ResultsAlreadyConsumedException < Exception
      end

      include Enumerable

      # @return the original result from the Neo4j Cypher Engine, once forward read only !
      attr_reader :source, :unwrapped

      def initialize(source, query, unwrapped = nil)
        @source = source
        @struct = Struct.new(*source.columns.to_a.map!(&:to_sym)) unless source.columns.empty?
        @unread = true
        @query = query
        @unwrapped = unwrapped
      end

      def to_s
        @query
      end

      def unwrapped?
        !!unwrapped
      end

      def inspect
        "Enumerable query: '#{@query}'"
      end

      # @return [Array<Symbol>] the columns in the query result
      def columns
        @source.columns.map!(&:to_sym)
      end

      def error?
        false
      end

      def each
        fail ResultsAlreadyConsumedException unless @unread

        if block_given?
          @source.each do |row|
            yield(row.each_with_object(@struct.new) do |(column, value), result|
              result[column.to_sym] = unwrap(value)
            end)
          end
        else
          Enumerator.new(self)
        end
      end

      private

      def unwrap(value)
        if !value.nil? && value.respond_to?(:to_a)
          value.respond_to?(:to_hash) ? value.to_hash : value.map { |v| unwrap(v) }
        else
          (!value.respond_to?(:wrapper) || unwrapped?) ? value : value.wrapper
        end
      end
    end
  end
end
