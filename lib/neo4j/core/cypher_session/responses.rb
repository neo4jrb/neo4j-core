require 'neo4j/core/cypher_session/result'

module Neo4j
  module Core
    class CypherSession
      module Responses
        MAP = {}

        class Base
          include Enumerable

          def each
            results.each do |result|
              yield result
            end
          end

          def wrap_by_level(none_value)
            case @wrap_level
            when :none
              if none_value.is_a?(Array)
                none_value.map(&:symbolize_keys)
              else
                none_value.symbolize_keys
              end
            when :core_entity
              yield
            when :proc
              yield.wrap
            else
              fail ArgumentError, "Invalid wrap_level: #{@wrap_level.inspect}"
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
