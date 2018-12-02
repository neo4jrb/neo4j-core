require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/responses/http'
require 'uri'

# TODO: Work with `Query` objects
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class HTTP < Base
          attr_reader :requestor, :url

          def initialize(url, options = {})
            @url = url
            @options = options
          end

          DEFAULT_FARADAY_CONFIGURATOR = proc do |faraday|
            require 'typhoeus'
            require 'typhoeus/adapters/faraday'
            faraday.adapter :typhoeus
          end

          def connect
            @requestor = Requestor.new(@url, USER_AGENT_STRING, self.class.method(:instrument_request), @options.fetch(:faraday_configurator, DEFAULT_FARADAY_CONFIGURATOR))
          end

          ROW_REST = %w[row REST]

          def query_set(transaction, queries, options = {})
            setup_queries!(queries, transaction)

            return unless path = transaction.query_path(options.delete(:commit))

            faraday_response = @requestor.post(path, queries)

            transaction.apply_id_from_url!(faraday_response.env[:response_headers][:location])

            wrap_level = options[:wrap_level] || @options[:wrap_level]
            Responses::HTTP.new(faraday_response, wrap_level: wrap_level).results
          end

          def version(_session)
            @version ||= @requestor.get('db/data/').body[:neo4j_version]
          end

          # Schema inspection methods
          def indexes(_session)
            response = @requestor.get('db/data/schema/index')

            check_for_schema_response_error!(response)
            list = response.body || []

            list.map do |item|
              {label: item[:label].to_sym,
               properties: item[:property_keys].map(&:to_sym)}
            end
          end

          CONSTRAINT_TYPES = {
            'UNIQUENESS' => :uniqueness
          }
          def constraints(_session, _label = nil, _options = {})
            response = @requestor.get('db/data/schema/constraint')

            check_for_schema_response_error!(response)
            list = response.body || []
            list.map do |item|
              {type: CONSTRAINT_TYPES[item[:type]],
               label: item[:label].to_sym,
               properties: item[:property_keys].map(&:to_sym)}
            end
          end

          def check_for_schema_response_error!(response)
            if response.body.is_a?(Hash) && response.body.key?(:errors)
              message = response.body[:errors].map { |error| "#{error[:code]}: #{error[:message]}" }.join("\n    ")
              fail CypherSession::ConnectionFailedError, "Connection failure: \n    #{message}"
            elsif !response.success?
              fail CypherSession::ConnectionFailedError, "Connection failure: \n    status: #{response.status} \n    #{response.body}"
            end
          end

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/http'
            Neo4j::Core::CypherSession::Transactions::HTTP
          end

          # Schema inspection methods
          def indexes_for_label(label)
            url = db_data_url + "schema/index/#{label}"
            @connection.get(url)
          end

          instrument(:request, 'neo4j.core.http.request', %w[method url body]) do |_, start, finish, _id, payload|
            ms = (finish - start) * 1000
            " #{ANSI::BLUE}HTTP REQUEST:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{payload[:method].upcase} #{payload[:url]} (#{payload[:body].size} bytes)"
          end

          def connected?
            !!@requestor
          end

          def supports_metadata?
            Gem::Version.new(version(nil)) >= Gem::Version.new('2.1.5')
          end

          # Basic wrapper around HTTP requests to standard Neo4j HTTP endpoints
          #  - Takes care of JSONifying objects passed as body (Hash/Array/Query)
          #  - Sets headers, including user agent string
          class Requestor
            include Adaptors::HasUri
            default_url('http://neo4:neo4j@localhost:7474')
            validate_uri { |uri| uri.is_a?(URI::HTTP) }
            def initialize(url, user_agent_string, instrument_proc, faraday_configurator)
              self.url = url
              @user = user
              @password = password
              @user_agent_string = user_agent_string
              @faraday = wrap_connection_failed! { faraday_connection(faraday_configurator) }
              @instrument_proc = instrument_proc
            end

            REQUEST_HEADERS = {'Accept'.to_sym => 'application/json; charset=UTF-8',
                               'Content-Type'.to_sym => 'application/json'}

            # @method HTTP method (:get/:post/:delete/:put)
            # @path Path part of URL
            # @body Body for the request.  If a Query or Array of Queries,
            #       it is automatically converted
            def request(method, path, body = '', _options = {})
              request_body = request_body(body)
              url = url_from_path(path)
              @instrument_proc.call(method, url, request_body) do
                wrap_connection_failed! do
                  @faraday.run_request(method, url, request_body, REQUEST_HEADERS)
                end
              end
            end

            # Convenience method to #request(:post, ...)
            def post(path, body = '', options = {})
              request(:post, path, body, options)
            end

            # Convenience method to #request(:get, ...)
            def get(path, body = '', options = {})
              request(:get, path, body, options)
            end

            private

            def faraday_connection(configurator)
              require 'faraday'
              require 'faraday_middleware/multi_json'

              Faraday.new(url) do |faraday|
                faraday.request :multi_json

                faraday.response :multi_json, symbolize_keys: true, content_type: 'application/json'

                faraday.headers['Content-Type'] = 'application/json'
                faraday.headers['User-Agent'] = @user_agent_string

                configurator.call(faraday)
              end
            end

            def password_config(options)
              options.fetch(:basic_auth, {}).fetch(:password, @password)
            end

            def username_config(options)
              options.fetch(:basic_auth, {}).fetch(:username, @user)
            end

            def request_body(body)
              return body if body.is_a?(String)

              body_is_query_array = body.is_a?(Array) && body.all? { |o| o.respond_to?(:cypher) }
              case body
              when Hash, Array
                return {statements: body.map(&self.class.method(:statement_from_query))} if body_is_query_array

                body
              else
                {statements: [self.class.statement_from_query(body)]} if body.respond_to?(:cypher)
              end
            end

            def wrap_connection_failed!
              yield
            rescue Faraday::ConnectionFailed => e
              raise CypherSession::ConnectionFailedError, "#{e.class}: #{e.message}"
            end

            class << self
              private

              def statement_from_query(query)
                {statement: query.cypher,
                 parameters: query.parameters || {},
                 resultDataContents: ROW_REST}
              end
            end

            def url_base
              "#{scheme}://#{host}:#{port}"
            end

            def url_from_path(path)
              url_base + (path[0] != '/' ? '/' + path : path)
            end
          end
        end
      end
    end
  end
end
