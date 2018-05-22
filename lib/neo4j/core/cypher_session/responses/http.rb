require 'neo4j/core/cypher_session/responses'

module Neo4j
  module Core
    class CypherSession
      module Responses
        class HTTP < Base
          attr_reader :results, :request_data

          def initialize(faraday_response, options = {})
            @faraday_response = faraday_response
            @request_data = request_data

            validate_faraday_response!(faraday_response)

            @wrap_level = options[:wrap_level] || Neo4j::Core::Config.wrapping_level

            @results = faraday_response.body[:results].map do |result_data|
              result_from_data(result_data[:columns], result_data[:data])
            end
          end

          def result_from_data(columns, entities_data)
            rows = entities_data.map do |entity_data|
              wrap_entity entity_data[:row], entity_data[:rest]
            end

            Result.new(columns, rows)
          end

          def wrap_entity(row_datum, rest_datum)
            if rest_datum.is_a?(Array)
              row_datum.zip(rest_datum).map { |row, rest| wrap_entity(row, rest) }
            elsif ident = identify_entity(rest_datum)
              send("wrap_#{ident}", rest_datum, row_datum)
            elsif rest_datum.is_a?(Hash)
              rest_datum.each_with_object({}) do |(k, v), result|
                result[k.to_sym] = wrap_entity(row_datum[k], v)
              end
            else
              row_datum
            end
          end

          private

          def identify_entity(rest_datum)
            return if !rest_datum.is_a?(Hash)
            self_string = rest_datum[:self]
            if self_string
              type = self_string.split('/')[-2]
              type.to_sym if %w[node relationship].include?(type)
            elsif %i[nodes relationships start end length].all? { |k| rest_datum.key?(k) }
              :path
            end
          end

          def wrap_node(rest_datum, row_datum)
            wrap_by_level(row_datum) do
              metadata_data = rest_datum[:metadata]
              ::Neo4j::Core::Node.new(id_from_rest_datum(rest_datum),
                                      metadata_data && metadata_data[:labels],
                                      rest_datum[:data])
            end
          end

          def wrap_relationship(rest_datum, row_datum)
            wrap_by_level(row_datum) do
              metadata_data = rest_datum[:metadata]
              ::Neo4j::Core::Relationship.new(id_from_rest_datum(rest_datum),
                                              metadata_data && metadata_data[:type],
                                              rest_datum[:data],
                                              id_from_url(rest_datum[:start]),
                                              id_from_url(rest_datum[:end]))
            end
          end

          def wrap_path(rest_datum, row_datum)
            wrap_by_level(row_datum) do
              nodes = rest_datum[:nodes].each_with_index.map do |url, i|
                Node.from_url(url, row_datum[2 * i])
              end
              relationships = rest_datum[:relationships].each_with_index.map do |url, i|
                Relationship.from_url(url, row_datum[(2 * i) + 1])
              end

              ::Neo4j::Core::Path.new(nodes, relationships, rest_datum[:directions])
            end
          end

          def id_from_rest_datum(rest_datum)
            if rest_datum[:metadata]
              rest_datum[:metadata][:id]
            else
              id_from_url(rest_datum[:self])
            end
          end

          def id_from_url(url)
            url.split('/').last.to_i
          end

          def validate_faraday_response!(faraday_response)
            if faraday_response.body.is_a?(Hash) && error = faraday_response.body[:errors][0]
              fail CypherError.new_from(error[:code], error[:message], error[:stack_trace])
            end

            return if (200..299).cover?(status = faraday_response.status)

            fail CypherError, "Expected 200-series response for #{faraday_response.env.url} (got #{status})"
          end
        end
      end
    end
  end
end
