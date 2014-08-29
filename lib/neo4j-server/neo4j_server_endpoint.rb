#require 'httpclient'
#require 'typhoeus'
require 'faraday'
require 'faraday_middleware'

module Neo4j::Server
  class Neo4jServerEndpoint

    class Response
      attr_reader :response
      def initialize(response)
        @response = response
        #puts "RESPONSE #{@response.success?}/#{@response.class}, status #{@response.status.inspect}"
        #puts "BODY #{@response.body.inspect}"
      end

      def [](value)
        body[value]
      end

      def code
        @response.status
      end

      def headers
        puts "HEADERS #{@response.headers.inspect}"
        @response.headers
      end

      def request_uri
        # HTTP CLIENT
        #@response.header.request_uri.to_s
      end

      def body
        @response.body
      end
    end

    attr_reader :conn

    # @example basic auth
    #   Neo4jServerEndpoint.new(:basic_auth: { username: 'foo', password: 'bar'})
    # See http://rubydoc.info/gems/faraday/0.9.0/Faraday.new
    def initialize(params = {})
      @conn = Faraday.new do |b|
        b.request :basic_auth, params[:basic_auth][:username], params[:basic_auth][:password] if params[:basic_auth]
        b.request :json
        b.response :logger
        b.response :json, :content_type => "application/json"
        #b.use Faraday::Response::RaiseError
        b.adapter  Faraday.default_adapter
      end
    end

    def get(url, query={})
      Response.new @conn.get(url, query)
    end

    def post(url, payload=nil)
#      Response.new @conn.post(url, payload)
      if (payload)
        Response.new @conn.post(url, payload)
      else
        r = @conn.post do |req|
          req.url url
          req.headers['Content-Type'] = 'application/json'
        end
        Response.new r # @conn.post(url)
      end


    end

    def delete(url, params={})
      puts "DELETE, params #{params.inspect}"
      Response.new @conn.delete(url, params)
    end

  end
end