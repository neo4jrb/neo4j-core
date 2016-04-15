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

          def wrap_entity(row_data, rest_data)
            row_data.each_with_index.map do |row_datum, i|
              rest_datum = rest_data[i]

              if rest_datum.is_a?(Array)
                wrap_entity(row_datum, rest_datum)
              else
                _wrap_entity(rest_datum, row_datum)
              end
            end
          end

          private

          def _wrap_entity(rest_datum, row_datum)
            case @wrap_level
            when :none
              row_datum
            when :core_entity, :proc
              if (ident = identify_entity(rest_datum))
                result = send("wrap_#{ident}", rest_datum, row_datum)

                @wrap_level == :proc ? result.wrap : result
              else
                row_datum
              end
            else
              fail ArgumentError, "Inalid wrap_level: #{@wrap_level.inspect}"
            end
          end

          def identify_entity(rest_datum)
            return if !rest_datum.is_a?(Hash)
            self_string = rest_datum[:self]
            if self_string
              type = self_string.split('/')[-2]
              type.to_sym if %w(node relationship).include?(type)
            elsif [:nodes, :relationships, :start, :end, :length].all? { |k| rest_datum.key?(k) }
              :path
            end
          end

          def wrap_node(rest_datum, _)
            metadata_data = rest_datum[:metadata]
            ::Neo4j::Core::Node.new(id_from_rest_datum(rest_datum),
                                    metadata_data && metadata_data[:labels],
                                    rest_datum[:data])
          end

          def wrap_relationship(rest_datum, _)
            metadata_data = rest_datum[:metadata]
            ::Neo4j::Core::Relationship.new(id_from_rest_datum(rest_datum),
                                            metadata_data && metadata_data[:type],
                                            rest_datum[:data],
                                            id_from_url(rest_datum[:start]),
                                            id_from_url(rest_datum[:end]))
          end

          def wrap_path(rest_datum, row_datum)
            nodes = rest_datum[:nodes].each_with_index.map do |url, i|
              Node.from_url(url, row_datum[2 * i])
            end
            relationships = rest_datum[:relationships].each_with_index.map do |url, i|
              Relationship.from_url(url, row_datum[(2 * i) + 1])
            end

            ::Neo4j::Core::Path.new(nodes, relationships, rest_datum[:directions])
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
              error = <<-ERROR
  Request to: #{ANSI::BOLD}#{faraday_response.env.url}#{ANSI::CLEAR}
  #{ANSI::CYAN}#{error[:code]}#{ANSI::CLEAR}: #{error[:message]}
  #{error[:stackTrace]}
ERROR

              fail CypherError, error
            end

            return if (200..299).cover?(status = faraday_response.status)

            fail CypherError, "Expected 200-series response for #{faraday_response.env.url} (got #{status})"
          end
        end
      end
    end
  end
end
