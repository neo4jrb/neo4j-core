module Neo4j::Server
  module HttpHelper
    def self.remember_auth(*options)
      if options.length == 2 # contains url + auth params
        @auth = options.last if options.last[:basic_auth]
      end
    end

    ["get", "post"].each do |verb|
      define_singleton_method verb do |url, *params|
        unless @auth.nil?
          params.push({}) if params.empty?
          params.last.merge!(@auth)
        end

        HTTParty.send(verb, url, *params)
      end
    end
  end
end