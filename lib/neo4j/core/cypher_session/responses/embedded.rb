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
            return entity.to_a.map { |e| wrap_entity(e) } if entity.respond_to?(:to_a)

            if entity.is_a?(Java::OrgNeo4jKernelImplCore::NodeProxy)
              wrap_node(entity)
            elsif entity.is_a?(Java::OrgNeo4jKernelImplCore::RelationshipProxy)
              wrap_relationship(entity)
            elsif entity.respond_to?(:path_entities)
              wrap_path(entity)
            else
              # Convert from Java?
              entity
            end
          end

          def wrap_node(entity)
            ::Neo4j::Core::Node.new(entity.get_id,
                                    entity.get_labels.to_a,
                                    get_entity_properties(entity)).wrap
          end

          def wrap_relationship(entity)
            ::Neo4j::Core::Relationship.new(entity.get_id,
                                            entity.get_type.name,
                                            get_entity_properties(entity)).wrap
          end

          def wrap_path(entity)
            ::Neo4j::Core::Path.new(entity.nodes.map(&method(:wrap_node)),
                                    entity.relationships.map(&method(:wrap_relationship)),
                                    nil).wrap
          end

          def get_entity_properties(entity)
            entity.get_property_keys.each_with_object({}) do |key, result|
              result[key.to_sym] = entity.get_property(key)
            end
          end
        end
      end
    end
  end
end
