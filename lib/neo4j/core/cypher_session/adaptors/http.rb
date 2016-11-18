require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/responses/http'

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

          def connect
            @requestor = Requestor.new(@url, USER_AGENT_STRING, self.class.method(:instrument_request), @options[:http_adaptor])
          rescue Faraday::ConnectionFailed => e
            raise CypherSession::ConnectionFailedError, "#{e.class}: #{e.message}"
          end

          ROW_REST = %w(row REST)

          def query_set(transaction, queries, options = {})
            setup_queries!(queries, transaction)

            return unless path = transaction.query_path(options.delete(:commit))

            faraday_response = @requestor.post(path, queries)

            transaction.apply_id_from_url!(faraday_response.env[:response_headers][:location])

            wrap_level = options[:wrap_level] || @options[:wrap_level]
            Responses::HTTP.new(faraday_response, wrap_level: wrap_level).results
          end

          def version
            @version ||= @requestor.get('db/data/').body[:neo4j_version]
          end

          # Schema inspection methods
          def indexes(_session)
            response = @requestor.get('db/data/schema/index')

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

            list = response.body || []
            list.map do |item|
              {type: CONSTRAINT_TYPES[item[:type]],
               label: item[:label].to_sym,
               properties: item[:property_keys].map(&:to_sym)}
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

          instrument(:request, 'neo4j.core.http.request', %w(method url body)) do |_, start, finish, _id, payload|
            ms = (finish - start) * 1000
            " #{ANSI::BLUE}HTTP REQUEST:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{payload[:method].upcase} #{payload[:url]} (#{payload[:body].size} bytes)"
          end

          def connected?
            !!@requestor
          end

          # Basic wrapper around HTTP requests to standard Neo4j HTTP endpoints
          #  - Takes care of JSONifying objects passed as body (Hash/Array/Query)
          #  - Sets headers, including user agent string
          class Requestor
            include Adaptors::HasUri
            default_url('http://neo4:neo4j@localhost:7474')
            validate_uri { |uri| uri.is_a?(URI::HTTP) }

            def initialize(url, user_agent_string, instrument_proc, adaptor)
              self.url = url
              @user = user
              @password = password
              @user_agent_string = user_agent_string
              @faraday = faraday_connection(adaptor)
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
                @faraday.run_request(method, url, request_body, REQUEST_HEADERS) do |req|
                  # Temporary
                  # req.options.timeout = 5
                  # req.options.open_timeout = 5
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

            def faraday_connection(adaptor)
              require 'faraday'
              require 'faraday_middleware/multi_json'
              require 'typhoeus/adapters/faraday' if adaptor == :typhoeus

              Faraday.new(url) do |c|
                c.request :basic_auth, user, password
                c.request :multi_json

                c.response :multi_json, symbolize_keys: true, content_type: 'application/json'
                c.adapter(adaptor || :net_http_persistent)

                # c.response :logger, ::Logger.new(STDOUT), bodies: true

                c.headers['Content-Type'] = 'application/json'
                c.headers['User-Agent'] = @user_agent_string
              end
            end

            def request_body(body)
              return body if body.is_a?(String)

              body_is_query_array = body.is_a?(Array) && body.all? { |o| o.respond_to?(:cypher) }
              case body
              when Hash, Array
                if body_is_query_array
                  return {statements: body.map(&self.class.method(:statement_from_query))}
                end

                body
              else
                {statements: [self.class.statement_from_query(body)]} if body.respond_to?(:cypher)
              end
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
