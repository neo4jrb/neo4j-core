module Neo4j
  module Core
    module Traversal
      # Implements the Neo4j Predicate Java interface, only used internally.
      # @private
      class FilterPredicate
        include Java::OrgNeo4jGraphdbTraversal::PathEvaluator

        def initialize
          @procs = []
        end

        def add(proc)
          @procs << proc
        end

        # for the state parameter see - http://api.neo4j.org/1.8.1/org/neo4j/graphdb/traversal/BranchState.html
        def evaluate(path, state)
          if path.length == 0
            return Java::OrgNeo4jGraphdbTraversal::Evaluation::EXCLUDE_AND_CONTINUE
          end
          # find the first filter which returns false
          # if not found then we will accept this path
          if @procs.find { |p| !p.call(path) }.nil?
            Java::OrgNeo4jGraphdbTraversal::Evaluation::INCLUDE_AND_CONTINUE
          else
            Java::OrgNeo4jGraphdbTraversal::Evaluation::EXCLUDE_AND_CONTINUE
          end

        end
      end
    end
  end
end