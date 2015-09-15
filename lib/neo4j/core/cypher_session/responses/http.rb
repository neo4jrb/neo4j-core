require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class HTTP < Base
          attr_reader :results

          def initialize(faraday_response)
            @results = faraday_response.body[:results].map do |result_data|
              result_from_data(result_data[:columns], result_data[:data])
            end
          end

          def result_from_data(columns, entities_data)
            rows = entities_data.map do |entity_data|
              resolve_result_element entity_data[:row], entity_data[:rest]
            end

            Result.new(columns, rows)
          end

          def resolve_result_element(row_data, rest_data)
            row_data.each_with_index.map do |row_datum, i|
              rest_datum = rest_data[i]

              case
              when rest_datum[:labels] # node
                ::Neo4j::Core::Node.new(rest_datum[:metadata][:id], rest_datum[:metadata][:labels], rest_datum[:data])
              when rest_datum[:type] # relationship
                ::Neo4j::Core::Relationship.new(rest_datum[:metadata][:id], rest_datum[:metadata][:type], rest_datum[:data])
              when rest_datum[:directions]
                nodes = rest_datum[:nodes].each_with_index.map do |url, i|
                  Node.from_url(url, row_datum[2 * i])
                end
                relationships = rest_datum[:relationships].each_with_index.map do |url, i|
                  Relationship.from_url(url, row_datum[(2 * i) + 1])
                end

                ::Neo4j::Core::Path.new(nodes, relationships, rest_datum[:directions])
              else
                fail "Was not able to determine result entity type: #{rest_data.inspect}"
              end

            end
          end
        end
      end
    end
  end
end