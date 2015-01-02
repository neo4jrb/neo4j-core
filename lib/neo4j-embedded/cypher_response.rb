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
      attr_reader :source

      def initialize(source, query)
        @source = source
        @struct = Struct.new(*source.columns.to_a.map(&:to_sym))
        @unread = true
        @query = query
      end

      def to_s
        @query
      end

      def inspect
        "Enumerable query: '#{@query}'"
      end

      # @return [Array<Symbol>] the columns in the query result
      def columns
        @source.columns.map(&:to_sym)
      end

      def each
        fail ResultsAlreadyConsumedException unless @unread

        if block_given?
          @source.each do |row|
            yield(row.each_with_object(@struct.new) do |(column, value), result|
              result[column.to_sym] = (value.respond_to?(:wrapper) ? value.wrapper : value)
            end)
          end
        else
          Enumerator.new(self)
        end
      end
    end
  end
end
