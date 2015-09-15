require 'neo4j/core/node'
require 'neo4j/core/relationship'
require 'neo4j/core/path'

module Neo4j
  module Core
    class CypherSession
      class Result
        attr_reader :columns, :rows

        def initialize(columns, rows)
          @columns = columns.map(&:to_sym)
          @rows = rows
          @struct_class = Struct.new('CypherResult', *columns)
        end

        def structs
          @structs ||= rows.map do |row|
            @struct_class.new(*row)
          end
        end

        def hashes
          @hashes ||= rows.map do |row|
            Hash[@columns.zip(row)]
          end
        end
      end
    end
  end
end