# frozen_string_literal: true

require 'neo4j/core/cypher_session/responses/bolt'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class BoltRouting < Bolt
          def initialize(queries, client, flush_messages_proc, options = {})
            @client = client
            super(queries, flush_messages_proc, options)
          end

          private

          def extract_message_groups(flush_messages_proc)
            fields_messages = flush_messages_proc.call(@client)

            validate_message_type!(fields_messages[0], :success)

            result_messages = []
            messages = nil

            loop do
              messages = flush_messages_proc.call(@client)
              next if messages.nil?
              break if messages[0].type == :success
              result_messages.concat(messages)
            end

            [fields_messages[0].args[0]['fields'],
             result_messages,
             messages]
          end
        end
      end
    end
  end
end
