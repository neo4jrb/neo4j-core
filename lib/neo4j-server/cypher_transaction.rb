module Neo4j
  module Server
    # The CypherTransaction object lifecycle is as follows:
    # * It is initialized with the transactional endpoint URL and the connection object to use for communication. It does not communicate with the server to create this.
    # * The first query within the transaction sets the commit and execution addresses, :commit_url and :query_url.
    # * At any time, `failure` can be called to mark a transaction failed and trigger a rollback upon closure.
    # * `close` is called to end the transaction. It calls `commit` or `delete`.
    #
    # If a transaction is created and then closed without performing any queries, an OpenStruct is returned that behaves like a successfully closed query.
    class CypherTransaction
      include Neo4j::Transaction::Instance
      include Neo4j::Core::CypherTranslator
      include Resource

      attr_reader :commit_url, :query_url, :base_url, :connection

      def initialize(url, session_connection)
        @base_url = url
        @connection = session_connection
        register_instance
      end

      ROW_REST = %w(row REST)
      def _query(cypher_query, params = nil)
        fail 'Transaction expired, unable to perform query' if expired?
        statement = {statement: cypher_query, parameters: params, resultDataContents: ROW_REST}
        body = {statements: [statement]}

        response = @query_url ? query(body) : start(body)

        create_cypher_response(response)
      end

      def start(body)
        request(:post, @base_url, 201, body).tap do |response|
          @commit_url = response.body[:commit]
          @query_url = response.headers[:Location]

          fail "NO ENDPOINT URL #{connection} : HEAD: #{response.headers.inspect}" if !@query_url || @query_url.empty?

          init_resource_data(response.body, @base_url)
        end
      end

      def query(body)
        request(:post, @query_url, 200, body)
      end

      def delete
        return empty_response if !@commit_url || expired?

        request(:delete, @query_url, 200, nil, resource_headers)
      end

      def commit
        return empty_response if !@commit_url || expired?

        request(:post, @commit_url, 200, nil, resource_headers)
      end

      private

      def request(action, endpoint_url, expected_code = 200, body = nil, headers = {})
        connection.send(action, endpoint_url, body, headers).tap do |response|
          expect_response_code!(response, expected_code)
        end
      end

      def create_cypher_response(response)
        first_result = response.body[:results][0]

        CypherResponse.new(response, true).tap do |cypher_response|
          if response.body[:errors].empty?
            cypher_response.set_data(first_result)
          else
            first_error = response.body[:errors].first
            mark_expired if first_error[:message].match(/Unrecognized transaction id/)
            cypher_response.set_error(first_error)
          end
        end
      end

      def empty_response
        OpenStruct.new(status: 200, body: '')
      end
    end
  end
end
