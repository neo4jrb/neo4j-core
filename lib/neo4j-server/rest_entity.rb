module Neo4j::Server
  module RestEntity
    def neo_id
      resource_url_id
    end


    def del
      response = HTTParty.delete(resource_url, headers: resource_headers)
      expect_response_code(response, 204, "Can't delete entity")
      nil
    end

    def exist?
      response = HTTParty.get(resource_url, headers: resource_headers)
      case response.code
        when 200
          true
        when 404
          false
        else
          handle_response_error(response)
      end
    end
    def property_url(key)
      resource_url('property', key: key)
    end

    def get_property(key)
      response = HTTParty.get(property_url(key), headers: resource_headers)
      return convert_from_json_value(response.body) if response.code == 200
      body = JSON.parse(response.body)
      return nil if body['exception'] == 'NoSuchPropertyException'
      raise "Error getting property '#{key}', #{body['exception']}"
    end

    def set_property(key,value)
      response = HTTParty.put(property_url(key), headers: resource_headers, body: convert_to_json_value(value))
      expect_response_code(response, 204, "Can't update property #{key} with value '#{value}'")
      value
    end

    def remove_property(key)
      response = HTTParty.delete(property_url(key), headers: resource_headers)
      expect_response_code(response, 204, "Can't remove property #{key}")
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
          handle_response_error(response)
      end
    end

  end
end