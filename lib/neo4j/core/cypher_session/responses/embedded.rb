require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class Embedded < Base
          attr_reader :results, :request_data

          def initialize(execution_results)
            @results = execution_results.map do |execution_result|
              result_from_execution_result(execution_result)
            end
          end

          private

          def result_from_execution_result(execution_result)
            columns = execution_result.columns.to_a
            rows = execution_result.map do |execution_result_row|
              columns.map { |column| wrap_entity(execution_result_row[column]) }
            end
            Result.new(columns, rows)
          end

          def wrap_entity(entity)
            case entity
            when Java::OrgNeo4jKernelImplCore::NodeProxy
              ::Neo4j::Core::Node.new(entity.get_id, labels, props)
            when Java::OrgNeo4jKernelImplCore::RelationshipProxy
            when Java::OrgNeo4jCypherInternalCompilerV2_2::PathImpl
            else
              # Convert from Java?
              execution_result_entity
            end
          end
        end
      end
    end
  end
end
