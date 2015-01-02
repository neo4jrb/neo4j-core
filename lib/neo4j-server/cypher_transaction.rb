module Neo4j
  module Server
    class CypherTransaction
      include Neo4j::Transaction::Instance
      include Neo4j::Core::CypherTranslator
      include Resource

      attr_reader :commit_url, :exec_url

      class CypherError < StandardError
        attr_reader :code, :status
        def initialize(code, status, message)
          super(message)
          @code = code
          @status = status
        end
      end

      def initialize(response, url, connection)
        @connection = connection
        @commit_url = response.body['commit']
        @exec_url = response.headers['Location']
        fail "NO ENDPOINT URL #{@connection} : HEAD: #{response.headers.inspect}" if !@exec_url || @exec_url.empty?
        init_resource_data(response.body, url)
        expect_response_code(response, 201)
        register_instance
      end

      def _query(cypher_query, params = nil)
        statement = {statement: cypher_query, parameters: params, resultDataContents: %w(row REST)}
        body = {statements: [statement]}
        response = @connection.post(@exec_url, body)
        _create_cypher_response(response)
      end

      def _create_cypher_response(response)
        first_result = response.body['results'][0]

        cr = CypherResponse.new(response, true)
        if !response.body['errors'].empty?
          first_error = response.body['errors'].first
          cr.set_error(first_error['message'], first_error['code'], first_error['code'])
        else
          cr.set_data(first_result['data'], first_result['columns'])
        end
        cr
      end

      def _delete_tx
        response = @connection.delete(@exec_url, headers: resource_headers)
        expect_response_code(response, 200)
        response
      end

      def _commit_tx
        response = @connection.post(@commit_url)

        expect_response_code(response, 200)
        response
      end
    end
  end
end
