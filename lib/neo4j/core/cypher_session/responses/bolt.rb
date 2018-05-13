require 'neo4j/core/cypher_session/responses'
require 'active_support/core_ext/hash/keys'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class Bolt < Base
          attr_reader :results, :result_info

          def initialize(queries, flush_messages_proc, options = {})
            @wrap_level = options[:wrap_level] || Neo4j::Core::Config.wrapping_level

            @results = queries.map do
              fields, result_messages, _footer_messages = extract_message_groups(flush_messages_proc)
              # @result_info = footer_messages[0].args[0]

              data = result_messages.map do |result_message|
                validate_message_type!(result_message, :record)

                result_message.args[0]
              end

              result_from_data(fields, data)
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
              wrap_structure(entity_data)
            when Hash
              entity_data.each_with_object({}) do |(k, v), result|
                result[k.to_sym] = wrap_entity(v)
              end
            else
              entity_data
            end
          end

          private

          def extract_message_groups(flush_messages_proc)
            fields_messages = flush_messages_proc.call

            validate_message_type!(fields_messages[0], :success)

            result_messages = []
            messages = nil

            loop do
              messages = flush_messages_proc.call
              next if messages.nil?
              break if messages[0].type == :success
              result_messages.concat(messages)
            end

            [fields_messages[0].args[0]['fields'],
             result_messages,
             messages]
          end

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
            wrap_by_level(properties) { ::Neo4j::Core::Node.new(id, labels, properties) }
          end

          def wrap_relationship(id, from_node_id, to_node_id, type, properties)
            wrap_by_level(properties) { ::Neo4j::Core::Relationship.new(id, type, properties, from_node_id, to_node_id) }
          end

          def wrap_unbound_relationship(id, type, properties)
            wrap_by_level(properties) { ::Neo4j::Core::Relationship.new(id, type, properties) }
          end

          def wrap_path(nodes, relationships, directions)
            none_value = nodes.zip(relationships).flatten.compact.map { |obj| obj.list.last }
            wrap_by_level(none_value) do
              ::Neo4j::Core::Path.new(nodes.map(&method(:wrap_entity)),
                                      relationships.map(&method(:wrap_entity)),
                                      directions.map(&method(:wrap_direction)))
            end
          end

          def wrap_direction(_direction_int)
            ''
          end

          def validate_message_type!(message, type)
            case message.type
            when type
              nil
            when :failure
              data = message.args[0]
              throw :cypher_bolt_failure, data
            else
              fail "Unexpected message type: #{message.type} (#{message.inspect})"
            end
          end
        end
      end
    end
  end
end
