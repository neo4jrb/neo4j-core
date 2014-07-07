module Neo4j::Embedded

  # Wraps the Cypher query result.
  # Loads the node and relationships wrapper if possible and use symbol as column keys.
  # This is typically used in the native neo4j bindings since result does is not a Ruby enumerable with symbols as keys.
  # @note The result is a once forward read only Enumerable, work if you need to read the result twice - use #to_a
  #
  class ResultWrapper
    class ResultsAlreadyConsumedException < Exception;
    end

    include Enumerable

    # @return the original result from the Neo4j Cypher Engine, once forward read only !
    attr_reader :source

    def initialize(source, map_return_procs, query)
      @source = source
      @struct = Struct.new(*source.columns.to_a.map(&:to_sym))
      @unread = true
      @map_return_procs = map_return_procs
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
      raise ResultsAlreadyConsumedException unless @unread

      if block_given?
        method = @map_return_procs.is_a?(Hash) ? :multi_column_mapping : :single_column_mapping

        @source.each do |row|
          yield self.send(method, row)
        end
      else
        Enumerator.new(self)
      end
    end


    private

    def multi_column_mapping(row)
      row.each_with_object(@struct.new) do |(column, value), result|
        key = column.to_sym
        proc = @map_return_procs[key]

        result[key] = wrap_result(proc ? proc.call(value) : value)
      end
    end

    def single_column_mapping(row)
      wrap_result(@map_return_procs.call(row.first))
    end

    def wrap_result(value)
      value.respond_to?(:wrapper) ? value.wrapper : value
    end


  end
end

