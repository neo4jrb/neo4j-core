require 'neo4j/core/cypher_session/result'

module Neo4j
  module Core
    class CypherSession
      module Responses
        MAP = {}

        class Base
          class CypherError < StandardError; end

          include Enumerable

          def each
            results.each do |result|
              yield result
            end
          end

          def results
            fail '#results not implemented!'
          end
        end
      end
    end
  end
end
