module Neo4j::Server
  class RestDatabase
    include Resource

    def initialize(endpoint_url)
      connect_to_server(endpoint_url)
      Neo4j::Database.register_instance(self)
    end

    def connect_to_server(endpoint_url)
      # get the root resource
      response = HTTParty.get(endpoint_url)
      expect_response_code(endpoint_url,response,200)
      root_data = JSON.parse(response.body)
      data_url = root_data['data']

      # get the data resource
      response = HTTParty.get(data_url)
      expect_response_code(data_url,response,200)

      data_resource = JSON.parse(response.body)

      # store the resource data
      init_resource_data(data_resource, endpoint_url)
    end

    def query(*params, &query_dsl)
      q = Neo4j::Cypher.query(*params, &query_dsl).to_s
      _query(q)
    end

    def _query(q, params={})
      url = resource_url('cypher')
      HTTParty.post(url, headers: resource_headers, body: {query: q}.to_json)
    end

    def create_node(props = nil, *labels)
      url = resource_url(:node)
      response = HTTParty.post(url, headers: resource_headers, body: props.to_json)
      RestNode.new(self, response, response.headers['location'])
    end

    def load(neo_id)
      wrap_resource(:node, RestNode, neo_id)
    end

  end
end