require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class Driver < Base
          attr_reader :results

          def initialize(responses, options = {})
            @wrap_level = options[:wrap_level] || Neo4j::Core::Config.wrapping_level

            @results = responses.map(&method(:result_from_data))
          end

          def result_from_data(entities_data)
            rows = entities_data.map do |entity_data|
              wrap_value(entity_data.values)
            end

            Neo4j::Core::CypherSession::Result.new(entities_data.keys, rows)
          end

          def wrap_by_level(none_proc)
            super(@wrap_level == :none ? none_proc.call : nil)
          end

          private

          # In the future the ::Neo4j::Core::Node should either monkey patch or wrap Neo4j::Driver:Types::Node to avoid
          # multiple object creation. This is probably best done once the other adapters (http, embedded) are removed.
          def wrap_node(node)
            wrap_by_level(-> { node.properties }) { ::Neo4j::Core::Node.new(node.id, node.labels, node.properties) }
          end

          def wrap_relationship(rel)
            wrap_by_level(-> { rel.properties }) do
              ::Neo4j::Core::Relationship.new(rel.id, rel.type, rel.properties, rel.start_node_id, rel.end_node_id)
            end
          end

          def wrap_path(path)
            nodes = path.nodes
            relationships = path.relationships
            wrap_by_level(-> { nodes.zip(relationships).flatten.compact.map(&:properties) }) do
              ::Neo4j::Core::Path.new(nodes.map(&method(:wrap_node)),
                                      relationships.map(&method(:wrap_relationship)),
                                      nil) # remove directions from Path, looks like unused
            end
          end

          def wrap_value(value)
            if value.is_a? Array
              value.map(&method(:wrap_value))
            elsif value.is_a? Hash
              value.map { |key, val| [key, wrap_value(val)] }.to_h
            elsif value.is_a? Neo4j::Driver::Types::Node
              wrap_node(value)
            elsif value.is_a? Neo4j::Driver::Types::Relationship
              wrap_relationship(value)
            elsif value.is_a? Neo4j::Driver::Types::Path
              wrap_path(value)
            else
              value
            end
          end
        end
      end
    end
  end
end
