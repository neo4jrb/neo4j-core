module Neo4j::Server
  class CypherTransaction
    attr_reader :commit_url, :exec_url

    include Resource

    def initialize(db, response, url)
      @commit_url = response['commit']
      @exec_url = response.headers['location']
      init_resource_data(response, url)
      expect_response_code(response,201)
      self.class.current=self
    end

    def _query(cypher_query)
      body = {statements: [statement: cypher_query]}
      response = HTTParty.post(@exec_url, headers: resource_headers, body: body.to_json)
      expect_response_code(response, 200)
      response
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
      self.class.clear_current
      if failure?
        response = HTTParty.delete(@exec_url, headers: resource_headers)
      else
        response = HTTParty.post(@commit_url, headers: resource_headers)
      end
      expect_response_code(response,200)
      response
    end

    def self.current=(tx)
      raise "Already running a transaction" if current
      Thread.current[:neo4j_curr_tx] = tx
    end

    def self.clear_current
      Thread.current[:neo4j_curr_tx] = nil
    end

    def self.current
      Thread.current[:neo4j_curr_tx]
    end

  end
end
