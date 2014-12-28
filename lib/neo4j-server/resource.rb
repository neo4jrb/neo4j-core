module Neo4j
  module Server
    module Resource

      class ServerException < Exception
      end

      attr_reader :resource_data, :resource_url

      def init_resource_data(resource_data, resource_url)
        fail "Exception #{resource_data['exception']}" if resource_data['exception']
        @resource_url = resource_url
        @resource_data = resource_data
        fail "expected @resource_data to be Hash got #{@resource_data.class}" unless @resource_data.respond_to?(:[])
        self
      end


      def wrap_resource(db, rel, resource_class, verb = :get, statement = {}, connection)
        url = resource_url(rel)
        payload = statement.empty? ? nil : statement
        response = case verb
        when :get then connection.get(url, payload)
        when :post then connection.post(url, payload)
        else fail "Illegal verb #{verb}"
        end
        response.status == 404 ? nil : resource_class.new(db, response, url, connection)
      end

      def resource_url(rel = nil)
        return @resource_url if rel.nil?
        url = resource_data[rel.to_s]
        fail "No resource rel '#{rel}', available #{@resource_data.keys.inspect}" unless url
        url
      end

      def handle_response_error(response, msg = 'Error for request')
        fail ServerException.new("#{msg} #{response.env && response.env[:url].to_s}, #{response.status}, #{response.status}")
      end

      def expect_response_code(response, expected_code, msg = 'Error for request')
        handle_response_error(response, "Expected response code #{expected_code} #{msg}") unless response.status == expected_code
        response
      end

      def response_exception(response)
        return nil if response.body.nil? || response.body.empty?
        JSON.parse(response.body)['exception']
      end

      def resource_headers
        {'Content-Type' => 'application/json', 'Accept' => 'application/json', 'User-Agent' => ::Neo4j::Session.user_agent_string}
      end

      def resource_url_id(url = resource_url)
        url.match(/\/(\d+)$/)[1].to_i
      end

      def convert_from_json_value(value)
        JSON.parse(value, quirks_mode: true)
      end
    end
  end
end
