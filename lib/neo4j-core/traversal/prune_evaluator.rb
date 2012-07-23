module Neo4j
  module Core

    module Traversal
      # Implements the Neo4j PruneEvaluator Java interface, only used internally.
      # @private
      class PruneEvaluator
        include Java::OrgNeo4jGraphdbTraversal::Evaluator

        def initialize(proc)
          @proc = proc
        end

        def evaluate(path)
          return Java::OrgNeo4jGraphdbTraversal::Evaluation::EXCLUDE_AND_CONTINUE if path.length == 0
          if @proc.call(path)
            Java::OrgNeo4jGraphdbTraversal::Evaluation::INCLUDE_AND_PRUNE
          else
            Java::OrgNeo4jGraphdbTraversal::Evaluation::INCLUDE_AND_CONTINUE
          end
        end
      end
    end
  end
end