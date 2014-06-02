module Neo4j::Embedded

  # Wraps the Cypher query result.
  # Loads the node and relationships wrapper if possible and use symbol as column keys.
  # This is typically used in the native neo4j bindings since result does is not a Ruby enumerable with symbols as keys.
  # @notice The result is a once forward read only Enumerable, work if you need to read the result twice - use #to_a
  #
  class ResultWrapper
    class ResultsAlreadyConsumedException < Exception;
    end;

    include Enumerable

    # @return the original result from the Neo4j Cypher Engine, once forward read only !
    attr_reader :source

    def initialize(source, map_return_procs, query)
      @source = source
      @unread = true
      @map_return_procs = map_return_procs
      @query = query
    end

    def to_s
      @query
    end

    # @return [Array<Symbol>] the columns in the query result
    def columns
      @source.columns.map { |x| x.to_sym }
    end

    # for the Enumerable contract
    def each(&block)
      raise ResultsAlreadyConsumedException unless @unread

      if (block)
        case @map_return_procs
          when NilClass then
            each_no_mapping &block
          when Hash then
            each_multi_column_mapping &block
          else
            each_single_column_mapping &block
        end
      else
        Enumerator.new(self)
      end
    end


    private

    def each_no_mapping
      @source.each do |row|
        hash = {}
        row.each do |key, value|
          out[key.to_sym] = value
        end
        yield hash
      end
    end

    def each_multi_column_mapping
      @source.each do |row|
        hash = {}
        row.each do |key, value|
          k = key.to_sym
          proc = @map_return_procs[k]
          hash[k] = proc ? proc.call(value) : value
        end
        yield hash
      end
    end

    def each_single_column_mapping
      @source.each do |row|
        result = @map_return_procs.call(row.values.first)
        yield result
      end
    end

  end
end

