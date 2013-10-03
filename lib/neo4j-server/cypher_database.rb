module Neo4j::Server
  class CypherDatabase

    class << self
      include Resource

      def connect(endpoint_url)
        # get the root resource
        response = HTTParty.get(endpoint_url)
        expect_response_code(response,200)
        root_data = JSON.parse(response.body)
        CypherSession.new(root_data['data'], CypherMapping.new)
      end

    end

  end
end