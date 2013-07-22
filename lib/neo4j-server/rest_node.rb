module Neo4j::Server
  class RestNode
    include Neo4j::Server::Resource

    def initialize(response, url)
      data = JSON.parse(response.body)
      init_resource_data(data, url)
    end

    def neo_id
      resource_url_id
    end

    def [](key)
      url = resource_url('property', key: key)
      response = HTTParty.get(url, headers: resource_headers)
      return convert_from_json_value(response.body) if response.code == 200
      body = JSON.parse(response.body)
      return nil if body['exception'] == 'NoSuchPropertyException'
      raise "Error getting property '#{key}', #{body['exception']}"
    end

    def []=(key,value)
      url = resource_url('property', key: key)
      if value.nil?
        response = HTTParty.delete(url, headers: resource_headers, body: convert_to_json_value(value))
      else
        response = HTTParty.put(url, headers: resource_headers, body: convert_to_json_value(value))
      end
      expect_response_code(url, response, 204, "Can't update property #{key} with value '#{value}'")
      value
    end

    def props
      url = resource_url('properties')
      response = HTTParty.get(url, headers: resource_headers)
      case response.code
        when 200
          JSON.parse(response.body)
        when 204
          {}
        else
          handle_response_error(url, response)
      end
    end

    def exist?
      response = HTTParty.get(resource_url, headers: resource_headers)
      case response.code
        when 200
          true
        when 404
          false
        else
          handle_response_error(url, response)
      end
    end

    def del
      response = HTTParty.delete(resource_url, headers: resource_headers)
      expect_response_code(resource_url, response, 204, "Can't delete node")
      nil
    end

    class << self
      include Resource

      def create_node(props = nil, *labels)
        url = resource_url(:node)
        response = HTTParty.post(url, headers: resource_headers, body: props.to_json)
        RestNode.new(response, response.headers['location'])
      end

      def load(neo_id)
        wrap_resource(:node, RestNode, neo_id)
      end
    end

  end
end

