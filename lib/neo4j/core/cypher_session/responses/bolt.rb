require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class Bolt < Base
          attr_reader :results, :result_info

          def initialize(fields_messages, result_messages, footer_messages)
            validate_message_type!(fields_messages[0], :success)
            validate_message_type!(footer_messages[0], :success)

            columns = fields_messages[0].args[0]['fields']
            @result_info = footer_messages[0].args[0]

            @results = result_messages.map do |result_message|
              validate_message_type!(result_message, :record)

              result_from_data(columns, result_message.args[0])
            end
          end

          def result_from_data(columns, entities_data)
            rows = entities_data.map do |entity_data|
              wrap_entity(entity_data)
            end

            Result.new(columns, rows)
          end

          def wrap_entity(entity_data)
            case entity_data
            when Array
              entity_data.map(&method(:wrap_entity))
            when PackStream::Structure
              case entity_data.signature
              when 0x4E # Node
                wrap_node(*entity_data.list)
              when 0x52 # Relationship
                wrap_relationship(*entity_data.list)
              when 0x72
                wrap_unbound_relationship(*entity_data.list)
              when 0x50 # Path
                wrap_path(*entity_data.list)
              else
                fail CypherError, "Unsupported structure signature: #{entity_data.signature}"
              end
            else
              entity_data
            end
          end

          private

          def wrap_node(id, labels, properties)
            ::Neo4j::Core::Node.new(id, labels, properties).wrap
          end

          def wrap_relationship(id, from_node_id, to_node_id, type, properties)
            ::Neo4j::Core::Relationship.new(id, type, properties, from_node_id, to_node_id).wrap
          end

          def wrap_unbound_relationship(id, type, properties)
            ::Neo4j::Core::Relationship.new(id, type, properties).wrap
          end

          def wrap_path(nodes, relationships, directions)
            ::Neo4j::Core::Path.new(nodes.map(&method(:wrap_entity)),
                                    relationships.map(&method(:wrap_entity)),
                                    directions.map(&method(:wrap_direction)))
          end

          def wrap_direction(_direction_int)
            ''
          end

          def validate_message_type!(message, type)
            return if message.type == type

            fail CypherError, "Message was not of type #{type}"
          end
        end
      end
    end
  end
end
