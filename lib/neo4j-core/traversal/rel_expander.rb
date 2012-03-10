module Neo4j
  module Core
    module Traversal
      # Implements the Neo4j RelationshipExpander Java interface, only used internally.
      # @private
      class RelExpander
        include Java::OrgNeo4jGraphdb::RelationshipExpander

        attr_accessor :reversed

        def initialize(&block)
          @block = block
          @reverse = false
        end

        def self.create_pair(&block)
          normal = RelExpander.new(&block)
          reversed = RelExpander.new(&block)
          normal.reversed = reversed
          reversed.reversed = normal
          reversed.reverse!
          normal
        end

        def expand(node)
          @block.arity == 1 ? @block.call(node) : @block.call(node, @reverse)
        end

        def reverse!
          @reverse = true
        end
      end
    end
  end
end