require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/responses/http'

# TODO: Work with `Query` objects
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class HTTP < Base
          # @transaction_state valid states
          # nil, :open_requested, :open, :close_requested
          include Adaptors::HasUri
          default_url('http://neo4:neo4j@localhost:7474')
          validate_uri { |uri| uri.is_a?(URI::HTTP) }


          def initialize(url, _options = {})
            self.url = url
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

            return unless url = full_transaction_url

            faraday_response = self.class.instrument_request(url, request_data) do
              @connection.post(url, request_data)
            end

            store_transaction_id!(faraday_response)

            Responses::HTTP.new(faraday_response, request_data).results
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

          # Schema inspection methods
          def indexes_for_label(label)
            url = db_data_url + "schema/index/#{label}"
            response = @connection.get(url)

            if response.body && response.body[0]
              response.body[0][:property_keys].map(&:to_sym)
            else
              []
            end
          end

          def uniqueness_constraints_for_label(label)
            url = db_data_url + "schema/constraint/#{label}/uniqueness"
            response = @connection.get(url)

            if response.body && response.body[0]
              response.body[0][:property_keys].map(&:to_sym)
            else
              []
            end
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
            path = ''
            path << "/#{@transaction_id}" if [:open, :close_requested].include?(@transaction_state)
            path << '/commit' if [nil, :close_requested].include?(@transaction_state)
            path = nil if @transaction_state == :close_requested && !@transaction_id

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
              c.headers['User-Agent'] = USER_AGENT_STRING
            end
          end
        end
      end
    end
  end
end
