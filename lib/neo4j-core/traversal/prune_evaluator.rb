module Neo4j
  module Core

    # Implements the Neo4j PruneEvaluator Java interface, only used internally.
    # @private
    module Traversal
      class PruneEvaluator
        include Java::OrgNeo4jGraphdbTraversal::PruneEvaluator

        def initialize(proc)
          @proc = proc
        end

        def prune_after(path)
          @proc.call(path)
        end
      end
    end
  end
end
