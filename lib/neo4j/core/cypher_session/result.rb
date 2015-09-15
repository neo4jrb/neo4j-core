require 'neo4j/core/node'
require 'neo4j/core/relationship'
require 'neo4j/core/path'

module Neo4j
  module Core
    class CypherSession
      class Result
        def initialize(columns, row)
          @columns = columns
          @row = row
        end
      end
    end
  end
end