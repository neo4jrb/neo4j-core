module Neo4j::Server
  class RestDatabase
    include Resource

    def initialize(endpoint_url)
      connect_to_server(endpoint_url)
      Neo4j::Database.register_instance(self)
    end

    def connect_to_server(endpoint_url)
      response = HTTParty.get(endpoint_url)
      expect_response_code(endpoint_url,response,200)
      root_data = JSON.parse(response.body)
      data_url = root_data['data']

      response = HTTParty.get(data_url)
      expect_response_code(endpoint_url,response,200)

      data = JSON.parse(response.body)
      RestNode.init_resource_data(data, endpoint_url)
    end

    def driver_for(clazz)
      # TODO
      RestNode
    end

    def query(*params, &query_dsl)
      q = Neo4j::Cypher.query(*params, &query_dsl).to_s
      _query(q)
    end

    def _query(q, params={})
      url = resource_url('cypher')
      HTTParty.post(url, headers: resource_headers, body: {query: q}.to_json)
    end

  end
end