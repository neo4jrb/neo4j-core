module Neo4j
  module Server
    module Resource

      class ServerException < Exception
      end

      attr_reader :resource_data, :resource_url

      def init_resource_data(resource_data, resource_url)
        raise "Exception #{response['exception']}" if resource_data['exception']
        @resource_url = resource_url
        @resource_data = resource_data
        raise "expected @resource_data to be Hash got #{@resource_data.class}" unless @resource_data.respond_to?(:[])
        self
      end


      def wrap_resource(db, rel, resource_class, args=nil, verb=:get, payload=nil)
        url = resource_url(rel, args)
        response = HTTParty.send(verb, url, headers: {'Content-Type' => 'application/json'}, body: payload)
        response.code == 404 ? nil : resource_class.new(db, response, url)
      end

      def resource_url(rel=nil, args=nil)
        return @resource_url unless rel
        url = @resource_data[rel.to_s]
        raise "No resource rel '#{rel}', available #{@resource_data.keys.inspect}" unless url
        return url unless args
        if (args.is_a?(Hash))
          args.keys.inject(url){|ack, key| ack.sub("{#{key}}",args[key].to_s)}
        else
          "#{url}/#{args.to_s}"
        end
      end

      def handle_response_error(response, msg="Error for request", url = response.request.path.to_s )
        raise ServerException.new("#{msg} #{url}, #{response.code}, #{response.body}")
      end

      def expect_response_code(response, expected_code, msg="Error for request", url=response.request.path.to_s )
        handle_response_error(response, "Expected response code #{expected_code} #{msg}",url) unless response.code == expected_code
        response
      end

      def response_exception(response)
        return nil if response.body.nil? || response.body.empty?
        JSON.parse(response.body)['exception']
      end

      def resource_headers
        {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
      end

      def resource_url_id(url = @resource_url)
        url.match(/\/(\d+)$/)[1].to_i
      end

      def convert_from_json_value(value)
        JSON.parse(value, :quirks_mode => true)
      end

      def convert_to_json_value(value)
        case value
          when String
            %Q["#{value}"]
          else
            value.to_s
        end
      end
    end
  end
end