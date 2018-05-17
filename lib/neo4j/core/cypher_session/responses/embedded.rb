require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class Embedded < Base
          attr_reader :results, :request_data

          def initialize(execution_results, options = {})
            # validate_response!(execution_results)

            @wrap_level = options[:wrap_level] || Neo4j::Core::Config.wrapping_level

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
            if entity.is_a?(Array) ||
               entity.is_a?(Java::ScalaCollectionConvert::Wrappers::SeqWrapper)
              entity.to_a.map(&method(:wrap_entity))
            else
              _wrap_entity(entity)
            end
          end

          def _wrap_entity(entity)
            case @wrap_level
            when :none then wrap_value(entity)
            when :core_entity, :proc
              if type = type_for_entity(entity)
                result = send("wrap_#{type}", entity)

                @wrap_level == :proc ? result.wrap : result
              else
                wrap_value(entity)
              end
            else
              fail ArgumentError, "Inalid wrap_level: #{@wrap_level.inspect}"
            end
          end

          def type_for_entity(entity)
            if entity.is_a?(Java::OrgNeo4jKernelImplCore::NodeProxy)
              :node
            elsif entity.is_a?(Java::OrgNeo4jKernelImplCore::RelationshipProxy)
              :relationship
            elsif entity.respond_to?(:path_entities)
              :path
            end
          end

          def wrap_node(entity)
            ::Neo4j::Core::Node.new(entity.get_id,
                                    entity.get_labels.map(&:to_s),
                                    get_entity_properties(entity))
          end

          def wrap_relationship(entity)
            ::Neo4j::Core::Relationship.new(entity.get_id,
                                            entity.get_type.name,
                                            get_entity_properties(entity),
                                            entity.get_start_node.id,
                                            entity.get_end_node.id)
          end

          def wrap_path(entity)
            ::Neo4j::Core::Path.new(entity.nodes.map(&method(:wrap_node)),
                                    entity.relationships.map(&method(:wrap_relationship)),
                                    nil)
          end

          def wrap_value(entity)
            case entity
            when Java::ScalaCollectionConvert::Wrappers::MapWrapper
              entity.each_with_object({}) { |(k, v), r| r[k.to_sym] = _wrap_entity(v) }
            when Java::OrgNeo4jKernelImplCore::NodeProxy, Java::OrgNeo4jKernelImplCore::RelationshipProxy
              entity.property_keys.each_with_object({}) { |key, hash| hash[key.to_sym] = entity.get_property(key) }
            else
              if entity.respond_to?(:path_entities) || entity.is_a?(Java::ScalaCollectionConvert::Wrappers::SeqWrapper)
                entity.to_a.map(&method(:_wrap_entity))
              else
                # Convert from Java?
                entity.is_a?(Hash) ? entity.symbolize_keys : entity
              end
            end
          end

          def get_entity_properties(entity)
            entity.get_property_keys.each_with_object({}) do |key, result|
              result[key.to_sym] = entity.get_property(key)
            end
          end

          def validate_response!(_execution_results)
            require 'pry'
          end
        end
      end
    end
  end
end
