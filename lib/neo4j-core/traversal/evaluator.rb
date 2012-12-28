module Neo4j
  module Core
    module Traversal

      # Implements the Neo4j Evaluator Java interface, only used internally.
      # @private
      class Evaluator
        include Java::OrgNeo4jGraphdbTraversal::PathEvaluator

        def initialize(&eval_block)
          @eval_block = eval_block
        end

        # Implements the Java Interface:
        #  evaluate(Path path,  BranchState<STATE> state)
        #  Evaluates a Path and returns an Evaluation containing information about whether or not to include it in the traversal result, i.e return it from the Traverser.
        def evaluate(path, state)
          ret = @eval_block.call(path)
          case ret
            when :exclude_and_continue then
              Java::OrgNeo4jGraphdbTraversal::Evaluation::EXCLUDE_AND_CONTINUE
            when :exclude_and_prune then
              Java::OrgNeo4jGraphdbTraversal::Evaluation::EXCLUDE_AND_PRUNE
            when :include_and_continue then
              Java::OrgNeo4jGraphdbTraversal::Evaluation::INCLUDE_AND_CONTINUE
            when :include_and_prune then
              Java::OrgNeo4jGraphdbTraversal::Evaluation::INCLUDE_AND_PRUNE
            else
              raise "Got #{ret}, only accept :exclude_and_continue,:exclude_and_prune,:include_and_continue and :include_and_prune"
          end
        end
      end

    end
  end
end
