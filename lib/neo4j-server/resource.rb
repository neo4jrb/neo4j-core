module Neo4j
  module Server
    module Resource
      class ServerException < Exception
      end

      attr_reader :resource_data, :resource_url

      def init_resource_data(resource_data, resource_url)
        fail "Exception #{resource_data['exception']}" if resource_data['exception']
        fail "Expected @resource_data to be Hash got #{resource_data.inspect}" unless resource_data.respond_to?(:[])

        @resource_url = resource_url
        @resource_data = resource_data

        self
      end


      def wrap_resource(key, resource_class, verb = :get, statement = {}, connection)
        fail "Illegal verb #{verb}" if not [:get, :post].include?(verb)

        url = resource_url(key)

        response = connection.send(verb, url, statement.empty? ? nil : statement)

        resource_class.new(response, url, connection) if response.status != 404
      end

      def resource_url(key = nil)
        return @resource_url if key.nil?

        @resource_data.fetch key.to_s
      rescue KeyError
        raise "No resource key '#{key}', available #{@resource_data.keys.inspect}"
      end

      def handle_response_error(response, msg = 'Error for request')
        fail ServerException, "#{msg} #{response.env && response.env[:url].to_s}, #{response.status}, #{response.status}"
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
