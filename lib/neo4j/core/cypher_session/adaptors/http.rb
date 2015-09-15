require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/responses/http'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class HTTP < Base
          def initialize(url, _options = {})
            @url = url
            @url_components = url_components!(url)
          end

          def connect
            @connection ||= connection
          end

          ROW_REST = %w(row REST)

          def queries(queries_and_parameters)
            fail 'Query attempted without a connection' if @connection.nil?

            statements_data = queries_and_parameters.map do |query, parameters|
              {
                statement: query,
                parameters: parameters || {},
                resultDataContents: ROW_REST
              }
            end

            faraday_response = @connection.post(full_transaction_url, statements: statements_data)

            Responses::HTTP.new(faraday_response).results
          end

          class Response < Responses::Base
            def initialize(_response_data)
            end
          end

          private

          def full_transaction_url
            "#{@protocol}://#{@host}:#{@port}/db/data/transaction/commit"
          end

          def connection
            Faraday.new(@url) do |c|
              c.request :basic_auth, @username, @password if !@username.nil? && !@password.nil?
              c.request :multi_json

              c.response :multi_json, symbolize_keys: true, content_type: 'application/json'
              c.use Faraday::Adapter::NetHttpPersistent

              c.headers['Content-Type'] = 'application/json'
              c.headers['User-Agent'] = user_agent_string
            end
          end

          URL_REGEXP = Regexp.new('^(https?)://(?:([^:]+):([^@]+)@)?([a-z0-9\.\-]+):(\d+)/?$', 'i')

          def url_components!(url)
            match = url.match(URL_REGEXP)

            fail ArgumentError, "Invalid URL: #{url.inspect}" if !match

            _, @protocol, @username, @password, @host, @port = match.to_a

            true
          end

          def user_agent_string
            gem, version = if defined?(::Neo4j::ActiveNode)
                             ['neo4j', ::Neo4j::VERSION]
                           else
                             ['neo4j-core', ::Neo4j::Core::VERSION]
                           end


            "#{gem}-gem/#{version} (https://github.com/neo4jrb/#{gem})"
          end
        end
      end
    end
  end
end
