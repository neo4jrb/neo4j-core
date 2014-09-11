#require 'httpclient'
#require 'typhoeus'
require 'faraday'
require 'faraday_middleware'

module Neo4j::Server
  class Neo4jServerEndpoint

    attr_reader :conn

    # @example basic auth
    #   Neo4jServerEndpoint.new(:basic_auth: { username: 'foo', password: 'bar'})
    # See http://rubydoc.info/gems/faraday/0.9.0/Faraday.new
    def initialize(params = {})
      @conn = Faraday.new do |b|
        b.request :basic_auth, params[:basic_auth][:username], params[:basic_auth][:password] if params[:basic_auth]
        b.request :json
        #b.response :logger
        b.response :json, :content_type => "application/json"
        #b.use Faraday::Response::RaiseError
        b.adapter  Faraday.default_adapter
      end
    end

    def get(url, query={})
      @conn.get(url, query)
    end

    def post(url, payload=nil)
      if (payload)
        @conn.post(url, payload)
      else
        @conn.post do |req|
          req.url url
          req.headers['Content-Type'] = 'application/json'
        end
      end
    end

    def delete(url, params={})
      @conn.delete(url, params)
    end

  end
end