require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/responses/http'

# TODO: Work with `Query` objects
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class HTTP < Base
          # @transaction_state valid states
          # nil, :open_requested, :open, :close_requested

          def initialize(url, _options = {})
            @url = url
            @url_components = url_components!(url)
            @transaction_state = nil
          end

          def connect
            @connection ||= connection
          end

          ROW_REST = %w(row REST)

          def query_set(queries)
            fail 'Query attempted without a connection' if @connection.nil?

            statements_data = queries.map do |query|
              {statement: query.cypher, parameters: query.parameters || {},
               resultDataContents: ROW_REST}
            end
            request_data = {statements: statements_data}

            # context option not implemented
            self.class.instrument_queries(queries)

            if url = full_transaction_url
              faraday_response = self.class.instrument_request(url, request_data) do
                puts "url: #{url.inspect}"
                puts 'request_data'
                puts request_data
                @connection.post(url, request_data)
              end

              store_transaction_id!(faraday_response)

              Responses::HTTP.new(faraday_response, request_data).results
            end
          end

          def start_transaction
            case @transaction_state
            when :open
              return
            when :close_requested
              fail 'Cannot start transaction when a close has been requested'
            end

            @transaction_state = :open_requested
          end

          def end_transaction
            if @transaction_state.nil?
              fail 'Cannot close transaction without starting one'
            end

            # This needs thought through more...
            @transaction_state = :close_requested
            query_set([])
            @transaction_state = nil
            @transaction_id = nil

            true
          end

          def transaction_started?
            !!@transaction_id
          end

          def version
            @version ||= @connection.get(db_data_url).body[:neo4j_version]
          end

          instrument(:request, 'neo4j.core.http.request', %w(url body)) do |_, start, finish, _id, payload|
            ms = (finish - start) * 1000

            " #{ANSI::BLUE}HTTP REQUEST:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{payload[:url]}"
          end

          private

          def store_transaction_id!(faraday_response)
            location = faraday_response.env[:response_headers][:location]

            return if !location

            @transaction_id = location.split('/').last.to_i
          end

          def full_transaction_url
            path = case @transaction_state
                   when nil then '/commit'
                   when :open_requested then ''
                   when :open then "/#{@transaction_id}"
                   when :close_requested
                     @transaction_id ? "/#{@transaction_id}/commit" : nil
                   end

            db_data_url + 'transaction' + path if path
          end

          def db_data_url
            url_base + 'db/data/'
          end

          def url_base
            "#{scheme}://#{host}:#{port}/"
          end

          def connection
            Faraday.new(@url) do |c|
              c.request :basic_auth, user, password
              c.request :multi_json

              c.response :multi_json, symbolize_keys: true, content_type: 'application/json'
              c.use Faraday::Adapter::NetHttpPersistent

              c.headers['Content-Type'] = 'application/json'
              c.headers['User-Agent'] = user_agent_string
            end
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
