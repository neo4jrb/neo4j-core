module Neo4j::Server
  class RestLabel < Neo4j::Label
    include Neo4j::Server::Resource
    attr_reader :name

    def initialize(db, url, name)
      @db = db
      @name = name
      @resource_url = url
    end


    def drop_index(*properties)
      properties.each do |property|
        index_url = "#@resource_url/#{property}"
        response = HTTParty.delete(index_url, headers: resource_headers)
        handle_response_error(response, "Unexpected response code #{response.code}",index_url) if response.code >= 500
      end
    end


    def create_index(*properties)
      #post /db/data/schema/index/foo {"property_keys": ["baaz"]}
      response = HTTParty.post(@resource_url, body: {"property_keys" => properties})
      expect_response_code(response, 200)
    end

    def indexes
      response = HTTParty.get(@resource_url, headers: resource_headers)
      data = convert_from_json_value(response.body)
      data.map do |index|
        index['property-keys'].map(&:to_sym)
      end
    end

    def find_nodes(key,value)

    end

  end
end