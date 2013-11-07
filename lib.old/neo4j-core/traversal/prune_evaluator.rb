module Neo4j
  module Core

    module Traversal
      # Implements the Neo4j PruneEvaluator Java interface, only used internally.
      # @private
      class PruneEvaluator
        include Java::OrgNeo4jGraphdbTraversal::PathEvaluator

        def initialize(proc)
          @proc = proc
        end

        # for the state parameter see - http://api.neo4j.org/1.8.1/org/neo4j/graphdb/traversal/BranchState.html
        def evaluate(path, state)
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