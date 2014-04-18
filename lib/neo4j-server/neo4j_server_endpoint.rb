module Neo4j::Server
  class Neo4jServerEndpoint
    def initialize(params = {})
      @params = params
    end

    def merged_options(options)
      options.merge!(@params)
    end

    def get(url, options={})
      HTTParty.get(url, merged_options(options))
    end

    def post(url, options={})
      HTTParty.post(url, merged_options(options))
    end

    def delete(url, options={})
      HTTParty.delete(url, merged_options(options))
    end

  end
end