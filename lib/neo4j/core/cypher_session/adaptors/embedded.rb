require 'neo4j/core/cypher_session/adaptors'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class Embedded < Base
          def initialize(_path, _options = {})
          end

          def connect
          end

          def queries(_queries_and_parameters)
          end
        end
      end
    end
  end
end
