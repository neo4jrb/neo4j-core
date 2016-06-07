require 'neo4j/core/cypher_session/responses'
require 'active_support/core_ext/hash/keys'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class Bolt < Base
          attr_reader :results, :result_info

          def initialize(flush_messages_proc)
            fields_messages = flush_messages_proc.call
            validate_message_type!(fields_messages[0], :success)
            result_messages = flush_messages_proc.call
            footer_messages = flush_messages_proc.call
            validate_message_type!(footer_messages[0], :success)

            @result_info = footer_messages[0].args[0]

            @results = result_messages.map do |result_message|
              validate_message_type!(result_message, :record)

              result_from_data(fields_messages[0].args[0]['fields'], result_message.args[0])
            end
          end

          def result_from_data(columns, entities_data)
            rows = entities_data.map do |entity_data|
              wrap_entity(entity_data)
            end

            Result.new(columns, [rows])
          end

          def wrap_entity(entity_data)
            case entity_data
            when Array
              entity_data.map(&method(:wrap_entity))
            when PackStream::Structure
              wrap_structure(entity_data)
            when Hash
              entity_data.symbolize_keys
            else
              entity_data
            end
          end

          private

          def wrap_structure(structure)
            case structure.signature
            when 0x4E then wrap_node(*structure.list)
            when 0x52 then wrap_relationship(*structure.list)
            when 0x72 then wrap_unbound_relationship(*structure.list)
            when 0x50 then wrap_path(*structure.list)
            else
              fail CypherError, "Unsupported structure signature: #{structure.signature}"
            end
          end

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
            case message.type
            when type
              return
            when :failure
              data = message.args[0]
              fail CypherError, "Job did not complete successfully\n\n#{data['code']}\n#{data['message']}"
            else
              fail "Unexpected message type: #{message.type}"
            end
          end
        end
      end
    end
  end
end
