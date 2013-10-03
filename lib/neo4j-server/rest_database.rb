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
      expect_response_code(response,200)
      root_data = JSON.parse(response.body)
      @data_url = root_data['data']

      # get the data resource
      response = HTTParty.get(@data_url)
      expect_response_code(response,200)

      data_resource = JSON.parse(response.body)

      # store the resource data
      init_resource_data(data_resource, endpoint_url)
    end



    def create_node(props = nil, labels=[])
      url = resource_url(:node)
      response = HTTParty.post(url, headers: resource_headers, body: props.to_json)
      node = RestNode.new(self, response, response.headers['location'])
      node.add_label(labels) unless labels.empty?
      node
    end

    def load_node(neo_id)
      wrap_resource(self, :node, RestNode, neo_id)
    end

    def create_label(name)
      # TODO hard coded url, not available yet in server ???
      url = "#{@data_url}schema/index/#{name}"
      RestLabel.new(self, url, name)
    end

  end
end