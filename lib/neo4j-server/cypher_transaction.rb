module Neo4j::Server
  class CypherTransaction
    attr_reader :commit_url, :exec_url

    include Resource

    class CypherError < StandardError
      attr_reader :code, :status
      def initialize(code, status, message)
        super(message)
        @code = code
        @status = status
      end
    end

    def initialize(db, response, url)
      @commit_url = response['commit']
      @exec_url = response.headers['location']
      init_resource_data(response, url)
      expect_response_code(response,201)
      Neo4j::Transaction.register(self)
    end

    def _query(cypher_query)
      body = {statements: [statement: cypher_query]}
      response = HTTParty.post(@exec_url, headers: resource_headers, body: body.to_json)

      first_result = response['results'][0]
      cr = CypherResponse.new(response, true)

      if (response['errors'].empty?)
        cr.set_data(first_result['data'], first_result['columns'])
      else
        first_error = response['errors'].first
        cr.set_error(first_error['message'], first_error['status'], first_error['code'])
      end
      cr
    end

    def success
      # this is need in the Java API
    end

    def failure
      @failure = true
    end

    def failure?
      !!@failure
    end

    def finish
      Neo4j::Transaction.unregister(self)
      if failure?
        response = HTTParty.delete(@exec_url, headers: resource_headers)
      else
        response = HTTParty.post(@commit_url, headers: resource_headers)
      end
      expect_response_code(response,200)
      response
    end


  end
end
