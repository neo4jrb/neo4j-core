module Neo4j::Server
  module HttpHelper
    def self.remember_auth(*url_params)
      @auth
      @auth = url_params.last[:basic_auth] if url_params.length == 2
    end

    ["get", "post", "delete"].each do |verb|
      define_singleton_method verb do |*params|
        params.push(basic_auth: @auth) unless @auth.nil?
        HTTParty.send(verb, *params)
      end
    end
  end
end