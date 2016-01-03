require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/responses/http'

# TODO: Work with `Query` objects
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class HTTP < Base
          attr_reader :requestor

          def initialize(url, options = {})
            @url = url
            @transaction_state = nil
            @options = options
          end

          def connect
            @requestor = Requestor.new(@url, self.class.method(:instrument_request))
          end

          ROW_REST = %w(row REST)

          def query_set(transaction, queries, options = {})
            fail 'Query attempted without a connection' if @requestor.nil?
            fail "Invalid transaction object: #{transaction}" if !transaction.is_a?(self.class.transaction_class)

            # context option not implemented
            self.class.instrument_queries(queries)

            return unless path = transaction.query_path(options.delete(:commit))

            faraday_response = @requestor.post(path, queries)

            transaction.set_id_from_url!(faraday_response.env[:response_headers][:location])

            wrap_level = options[:wrap_level] || @options[:wrap_level]
            Responses::HTTP.new(faraday_response, wrap_level: wrap_level).results
          end

          def version
            @version ||= @requestor.get('db/data/').body[:neo4j_version]
          end

          # Schema inspection methods
          def indexes_for_label(label)
            response = @requestor.get("schema/index/#{label}")

            if response.body && response.body[0]
              response.body[0][:property_keys].map(&:to_sym)
            else
              []
            end
          end

          def uniqueness_constraints_for_label(label)
            response = @requestor.get("schema/constraint/#{label}/uniqueness")

            if response.body && response.body[0]
              response.body[0][:property_keys].map(&:to_sym)
            else
              []
            end
          end

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/http'
            Neo4j::Core::CypherSession::Transactions::HTTP
          end

          instrument(:request, 'neo4j.core.http.request', %w(method url body)) do |_, start, finish, _id, payload|
            ms = (finish - start) * 1000

            " #{ANSI::BLUE}HTTP REQUEST:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{payload[:method].upcase} #{payload[:url]} (#{payload[:body].size} bytes)"
          end

          private

          # Basic wrapper around HTTP requests to standard Neo4j HTTP endpoints
          #  - Takes care of JSONifying objects passed as body (Hash/Array/Query)
          #  - Sets headers, including user agent string
          class Requestor
            def initialize(url = nil, instrument_proc)
              @url = url
              @url_components = url_components!(url)
              @faraday = faraday_connection
              @instrument_proc = instrument_proc
            end

            REQUEST_HEADERS = {:Accept => 'application/json; charset=UTF-8',
                               :'Content-Type' => 'application/json'}

            # @method HTTP method (:get/:post/:delete/:put)
            # @path Path part of URL
            # @body Body for the request.  If a Query or Array of Queries,
            #       it is automatically converted
            def request(method, path, body = '', _options = {})
              request_body = body_json(body)
              url = url_from_path(path)
              @instrument_proc.call(method, url, request_body) do
                @faraday.run_request(method, url, request_body, REQUEST_HEADERS)
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

            def faraday_connection
              require 'faraday'
              require 'faraday_middleware/multi_json'

              Faraday.new(@url) do |c|
                c.request :basic_auth, user, password
                c.request :multi_json

                c.response :multi_json, symbolize_keys: true, content_type: 'application/json'
                c.use Faraday::Adapter::NetHttpPersistent

                c.headers['Content-Type'] = 'application/json'
                c.headers['User-Agent'] = user_agent_string
              end
            end

            def body_json(body)
              return body if body.is_a?(String)

              body_is_query_array = body.is_a?(Array) && body.all? {|o| o.respond_to?(:cypher) }
              if body.is_a?(Hash) || (body.is_a?(Array) && !body_is_query_array)
                body
              elsif body.respond_to?(:cypher)
                {statements: [self.class.statement_from_query(body)]}
              elsif body_is_query_array
                {statements: body.map(&self.class.method(:statement_from_query))}
              end.to_json
            end

            def self.statement_from_query(query)
              {statement: query.cypher,
               parameters: query.parameters || {},
               resultDataContents: ROW_REST}
            end

            def url_from_path(path)
              url_base + (path[0] != '/' ? '/' + path : path)
            end

            def db_data_url
              url_base + 'db/data/'
            end

            def url_base
              "#{scheme}://#{host}:#{port}"
            end

            def url_components!(url)
              @uri = URI(url || 'http://localhost:7474')

              if !@uri.is_a?(URI::HTTP)
                fail ArgumentError, "Invalid URL: #{url.inspect}"
              end

              true
            end

            URI_DEFAULTS = {
              scheme: 'http',
              user: 'neo4j', password: 'neo4j',
              host: 'localhost', port: 7474
            }

            URI_DEFAULTS.each do |method, value|
              define_method(method) do
                @uri.send(method) || value
              end
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
end
