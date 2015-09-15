require 'neo4j/core/cypher_session/adaptors'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class Embedded < Base
          def initialize(path, options = {})
          end

          def connect
          end

          def query(cypher_string, parameters = {})
          end
        end
      end
    end
  end
end