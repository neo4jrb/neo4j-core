module Neo4j::Server
  class Neo4jServerEndpoint
    def initialize(url, params = nil)
      unless params.nil?
        @auth = params if params[:basic_auth]
      end
    end

    ["get", "post"].each do |verb|
      define_method verb do |url, *params|
        unless @auth.nil?
          params.push({}) if params.empty?
          params.last.merge!(@auth)
        end

        HTTParty.send(verb, url, *params)
      end
    end
  end
end