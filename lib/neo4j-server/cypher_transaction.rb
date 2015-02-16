module Neo4j
  module Server
    # The CypherTransaction object lifecycle is as follows:
    # * It is initialized with the transactional endpoint URL and the connection object to use for communication. It does not communicate with the server to create this.
    # * The first query within the transaction sets the commit and execution addresses, :commit_url and :exec_url.
    # * At any time, `failure` can be called to mark a transaction failed and trigger a rollback upon closure.
    # * `close` is called to end the transaction. It calls `_commit_tx` or `_delete_tx`.
    #
    # If a transaction is created and then closed without performing any queries, an OpenStruct is returned that behaves like a successfully closed query.
    class CypherTransaction
      include Neo4j::Transaction::Instance
      include Neo4j::Core::CypherTranslator
      include Resource

      attr_reader :commit_url, :exec_url, :base_url, :connection

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

        response = exec_url && commit_url ? connection.post(exec_url, body) : register_urls(body)
        _create_cypher_response(response)
      end

      def _delete_tx
        _tx_query(:delete, exec_url, headers: resource_headers)
      end

      def _commit_tx
        _tx_query(:post, commit_url, nil)
      end

      private

      def _tx_query(action, endpoint, headers = {})
        return empty_response if !commit_url || expired?
        response = connection.send(action, endpoint, headers)
        expect_response_code(response, 200)
        response
      end

      def register_urls(body)
        response = connection.post(base_url, body)
        @commit_url = response.body[:commit]
        @exec_url = response.headers[:Location]
        fail "NO ENDPOINT URL #{connection} : HEAD: #{response.headers.inspect}" if !exec_url || exec_url.empty?
        init_resource_data(response.body, base_url)
        expect_response_code(response, 201)
        response
      end

      def _create_cypher_response(response)
        first_result = response.body[:results][0]

        cr = CypherResponse.new(response, true)
        if response.body[:errors].empty?
          cr.set_data(first_result[:data], first_result[:columns])
        else
          first_error = response.body[:errors].first
          expired if first_error[:message].match(/Unrecognized transaction id/)
          cr.set_error(first_error[:message], first_error[:code], first_error[:code])
        end
        cr
      end

      def empty_response
        OpenStruct.new(status: 200, body: '')
      end
    end
  end
end
