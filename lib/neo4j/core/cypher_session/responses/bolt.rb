require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class Bolt < Base
          def initialize(faraday_response, request_data)
          end

          def result_from_data(columns, entities_data)
          end

          def wrap_entity(row_data, rest_data)
          end

        end
      end
    end
  end
end

