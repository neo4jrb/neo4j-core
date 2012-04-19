module Neo4j
  module Core
    module Cypher
      # Wraps the Cypher query result.
      # Loads the node and relationships wrapper if possible and use symbol as column keys.
      # @notice The result is a once forward read only Enumerable, work if you need to read the result twice - use #to_a
      #
      # @example
      #   result = Neo4j.query(@a, @b){|a,b| node(a,b).as(:n)}
      #   r = @query_result.to_a # can only loop once
      #   r.size.should == 2
      #   r.first.should include(:n)
      #   r[0][:n].neo_id.should == @a.neo_id
      #   r[1][:n].neo_id.should == @b.neo_id
      class ResultWrapper
        include Enumerable

        # @return the original result from the Neo4j Cypher Engine, once forward read only !
        attr_reader :source

        def initialize(source)
          @source = source
        end

        # @return [Array<Symbol>] the columns in the query result
        def columns
          @source.columns.map{|x| x.to_sym}
        end

        # for the Enumerable contract
        def each
          @source.each { |row| yield map(row) }
        end

        # Maps each row so that we can use symbols for column names.
        # @private
        def map(row)
          out = {} # move to a real hash!
          row.each do |key, value|
            out[key.to_sym] = value.respond_to?(:wrapper) ? value.wrapper : value
          end
          out
        end

      end
    end
  end
end
