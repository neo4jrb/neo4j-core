module Neo4j::Server
  class CypherTransaction
    attr_reader :commit_url, :exec_url

    include Resource
    include CypherHelper

    class CypherError < StandardError
      attr_reader :code, :status
      def initialize(code, status, message)
        super(message)
        @code = code
        @status = status
      end
    end

    def initialize(db, response, url)
      @commit_url = response['commit']
      @exec_url = response.headers['location']
      init_resource_data(response, url)
      expect_response_code(response,201)
      Neo4j::Transaction.register(self)
    end

    def _query(cypher_query, params=nil)
      statement = {statement: cypher_query}
      body = {statements: [statement]}

      if params
        # TODO can't get this working for some reason using parameters
        #props = params.keys.inject({}) do|ack, k|
        #  ack[k] = {name: params[k]}
        #  ack
        #end
        #statement[:parameters] = props

        # So we have to do this workaround
        params.each_pair do |k,v|
          statement[:statement].gsub!("{ #{k} }", escape_value(v))
        end
      end
      response = HTTParty.post(@exec_url, headers: resource_headers, body: body.to_json)

      first_result = response['results'][0]
      cr = CypherResponse.new(response, true)

      if (response['errors'].empty?)
        cr.set_data(first_result['data'], first_result['columns'])
      else
        first_error = response['errors'].first
        cr.set_error(first_error['message'], first_error['status'], first_error['code'])
      end
      cr
    end

    def success
      # this is need in the Java API
    end

    def failure
      @failure = true
    end

    def failure?
      !!@failure
    end

    def finish
      Neo4j::Transaction.unregister(self)
      if failure?
        response = HTTParty.delete(@exec_url, headers: resource_headers)
      else
        response = HTTParty.post(@commit_url, headers: resource_headers)
      end
      expect_response_code(response,200)
      response
    end


  end
end
