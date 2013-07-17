module Neo4j
  module Core
    module Traversal
      # Implements the Neo4j RelationshipExpander Java interface, only used internally.
      # @private
      class RelExpander
        include Java::OrgNeo4jGraphdb::PathExpander

        attr_accessor :reversed, :reverse

        def initialize(&block)
          @block = block
          @reversed = false
        end

        def self.create_pair(&block)
          normal = RelExpander.new(&block)
          reversed = RelExpander.new(&block)
          normal.reverse = reversed
          reversed.reversed = normal
          reversed.reverse!
          normal
        end

        def expand(node, _)
          @block.arity == 1 ? @block.call(node) : @block.call(node, @reversed)
        end

        def reverse!
          @reversed = true
        end
      end
    end
  end
end