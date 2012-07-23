module Neo4j
  module Core
    module Traversal
      # Implements the Neo4j Predicate Java interface, only used internally.
      # @private
      class FilterPredicate
        include Java::OrgNeo4jGraphdbTraversal::Evaluator

        def initialize
          @procs = []
        end

        def add(proc)
          @procs << proc
        end

        def evaluate(path)
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