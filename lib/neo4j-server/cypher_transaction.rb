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
        statement = {statement: cypher_query, parameters: params, resultDataContents: ROW_REST}
        body = {statements: [statement]}

        response = exec_url && commit_url ? connection.post(exec_url, body) : register_urls(body)
        _create_cypher_response(response).tap do |cypher_response|
          handle_transaction_errors(cypher_response)
        end
      end

      def _create_cypher_response(response)
        CypherResponse.create_with_tx(response)
      end

      # Replaces current transaction with invalid transaction indicating it was rolled back or expired on the server side. http://neo4j.com/docs/stable/status-codes.html#_classifications
      def handle_transaction_errors(response)
        tx_class = if response.transaction_not_found?
                     ExpiredCypherTransaction
                   elsif response.transaction_failed?
                     InvalidCypherTransaction
                   end

        register_invalid_transaction(tx_class) if tx_class
      end

      def register_invalid_transaction(tx_class)
        tx = tx_class.new(Neo4j::Transaction.current)
        Neo4j::Transaction.unregister_current
        tx.register_instance
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
        @commit_url = response.body['commit']
        @exec_url = response.headers['Location']
        fail "NO ENDPOINT URL #{connection} : HEAD: #{response.headers.inspect}" if !exec_url || exec_url.empty?
        init_resource_data(response.body, base_url)
        expect_response_code(response, 201)
        response
      end

      def empty_response
        OpenStruct.new(status: 200, body: '')
      end

      def valid?
        !invalid?
      end

      def expired?
        is_a? ExpiredCypherTransaction
      end

      def invalid?
        is_a? InvalidCypherTransaction
      end
    end

    class InvalidCypherTransaction < CypherTransaction
      attr_accessor :original_transaction

      def initialize(transaction)
        self.original_transaction = transaction
        mark_failed
      end

      def close
        Neo4j::Transaction.unregister(self)
      end

      def _query(cypher_query, params = nil)
        fail 'Transaction is invalid, unable to perform query'
      end
    end

    class ExpiredCypherTransaction < InvalidCypherTransaction
      def _query(cypher_query, params = nil)
        fail 'Transaction expired, unable to perform query'
      end
    end
  end
end
