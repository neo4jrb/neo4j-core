module Neo4j
  module Core
    module Cypher
      # Wraps the Cypher query result
      # Loads the wrapper if possible and use symbol as keys.
      class ResultWrapper
        include Enumerable

        # @return the original result from the Neo4j Cypher Engine
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

        # Maps each row
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
