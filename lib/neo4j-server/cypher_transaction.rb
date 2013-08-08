module Neo4j::Server
  class CypherTransaction
    attr_reader :commit_url, :exec_url

    include Resource

    def initialize(db, response, url)
      @commit_url = response['commit']
      @exec_url = response.headers['location']
      init_resource_data(response, url)
      expect_response_code(response,201)
    end

    def _query(cypher_query)
      body = {statements: [statement: cypher_query]}
      response = HTTParty.post(@exec_url, headers: resource_headers, body: body.to_json)
      expect_response_code(response,200)
      response
    end

    def success

    end

    def finish
      response = HTTParty.post(@commit_url, headers: resource_headers)
      Thread.current[:neo4j_curr_tx] = nil
      expect_response_code(response,200)
      response
    end
  end
end
