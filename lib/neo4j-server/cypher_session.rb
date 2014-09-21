module Neo4j::Server

  # Plugin
  Neo4j::Session.register_db(:server_db) do |*url_opts|
    Neo4j::Server::CypherSession.open(*url_opts)
  end

  class CypherSession < Neo4j::Session
    include Resource
    include Neo4j::Core::CypherTranslator
    
    alias_method :super_query, :query
    attr_reader :connection

    # @param [Hash] params could be empty or contain basic authentication user and password
    # @return [Faraday]
    # @see https://github.com/lostisland/faraday
    def self.create_connection(params)
      init_params = params[:initialize] and params.delete(:initialize)
      conn = Faraday.new(init_params) do |b|
        b.request :basic_auth, params[:basic_auth][:username], params[:basic_auth][:password] if params[:basic_auth]
        b.request :json
        #b.response :logger
        b.response :json, :content_type => "application/json"
        #b.use Faraday::Response::RaiseError
        b.adapter  Faraday.default_adapter
      end
      conn.headers = {'Content-Type' => 'application/json'}
      conn
    end

    # Opens a session to the database
    # @see Neo4j::Session#open
    #
    # @param [String] endpoint_url - the url to the neo4j server, defaults to 'http://localhost:7474'
    # @param [Hash] params faraday params, see #create_connection or an already created faraday connection
    def self.open(endpoint_url=nil, params = {})
      connection = params[:connection] || create_connection(params)
      url = endpoint_url || 'http://localhost:7474'
      response = connection.get(url)
      raise "Server not available on #{url} (response code #{response.status})" unless response.status == 200

      root_data = response.body
      data_url = root_data['data']
      data_url << '/' unless data_url.end_with?('/')

      CypherSession.new(data_url, connection)
    end

    def initialize(data_url, connection)
      @connection = connection
      Neo4j::Session.register(self)
      initialize_resource(data_url)
      Neo4j::Session._notify_listeners(:session_available, self)
    end

    def db_type
      :server_db
    end

    def to_s
      "#{self.class} url: '#{@resource_url}'"
    end

    def inspect
      "#{to_s} version: '#{version}'"
    end

    def version
      resource_data ? resource_data['neo4j_version'] : ''
    end

    def initialize_resource(data_url)
      response = @connection.get(data_url)
      expect_response_code(response,200)
      data_resource = response.body
      raise "No data_resource for #{response.body}" unless data_resource
      # store the resource data
      init_resource_data(data_resource, data_url)
    end

    def close
      super
      Neo4j::Transaction.unregister_current
    end

    def begin_tx
      if Neo4j::Transaction.current
        # Handle nested transaction "placebo transaction"
        Neo4j::Transaction.current.push_nested!
      else
        wrap_resource(self, 'transaction', CypherTransaction, :post, @connection)
      end
      Neo4j::Transaction.current
    end

    def create_node(props=nil, labels=[])
      l = labels.empty? ? "" : ":" + labels.map{|k| "`#{k}`"}.join(':')
      q = "CREATE (n#{l} #{cypher_prop_list(props)}) RETURN ID(n)"
      cypher_response = _query_or_fail(q, true)
      CypherNode.new(self, cypher_response)
    end

    def load_node(neo_id)
      cypher_response = _query("START n=node(#{neo_id}) RETURN n")
      if (!cypher_response.error?)
        result = cypher_response.entity_data(neo_id)
        CypherNode.new(self, result)
      elsif (cypher_response.error_status =~ /EntityNotFound/)
        return nil
      else
        cypher_response.raise_error
      end
    end

    def load_relationship(neo_id)
      cypher_response = _query("START r=relationship(#{neo_id}) RETURN TYPE(r)")
      if (!cypher_response.error?)
        CypherRelationship.new(self, neo_id, cypher_response.first_data)
      elsif (cypher_response.error_msg =~ /not found/)  # Ugly that the Neo4j API gives us this error message
        return nil
      else
        cypher_response.raise_error
      end
    end

    def create_label(name)
      CypherLabel.new(self, name)
    end

    def uniqueness_constraints(label)
      response = @connection.get("#{@resource_url}schema/constraint/#{label}/uniqueness")
      expect_response_code(response, 200)
      data_resource = response.body

      property_keys = data_resource.map do |row|
        row['property_keys'].map(&:to_sym)
      end

      {
          property_keys: property_keys
      }
    end

    def indexes(label)
      response = @connection.get("#{@resource_url}schema/index/#{label}")
      expect_response_code(response, 200)
      data_resource = response.body

      property_keys = data_resource.map do |row|
        row['property_keys'].map(&:to_sym)
      end

      {
          property_keys: property_keys
      }
    end

    def find_all_nodes(label_name)
      response = _query_or_fail("MATCH (n:`#{label_name}`) RETURN ID(n)")
      search_result_to_enumerable_first_column(response)
    end

    def find_nodes(label_name, key, value)
      value = "'#{value}'" if value.is_a? String
      
      response = _query_or_fail <<-CYPHER
        MATCH (n:`#{label_name}`)
        WHERE n.#{key} = #{value}
        RETURN ID(n)
      CYPHER
      search_result_to_enumerable_first_column(response)
    end

    def query(*args)
      if [[String], [String, Hash]].include?(args.map(&:class))
        query, params = args[0,2]
        response = _query(query, params)
        response.raise_error if response.error?
        response.to_node_enumeration(query)
      else
        options = args[0] || {}
        Neo4j::Core::Query.new(options.merge(session: self))
      end
    end

    def _query_data(q)
      r = _query_or_fail(q, true)
      # the response is different if we have a transaction or not
      Neo4j::Transaction.current ? r : r['data']
    end

    def _query_or_fail(q, single_row = false, params=nil)
      response = _query(q, params)
      response.raise_error if response.error?
      single_row ? response.first_data : response
    end

    def _query_entity_data(q, id=nil)
      response = _query(q)
      response.raise_error if response.error?
      response.entity_data(id)
    end

    def _query(q, params=nil)
      curr_tx = Neo4j::Transaction.current
      if (curr_tx)
        curr_tx._query(q, params)
      else
        url = resource_url('cypher')
        q = params.nil? ? {query: q} : {query: q, params: params}
        response = @connection.post(url, q)
        CypherResponse.create_with_no_tx(response)
      end
    end

    def search_result_to_enumerable_first_column(response)
      return [] unless response.data
      if Neo4j::Transaction.current
        search_result_to_enumerable_first_column_with_tx(response)
      else
        search_result_to_enumerable_first_column_without_tx(response)
      end
    end

    def search_result_to_enumerable_first_column_with_tx(response)
      Enumerator.new do |yielder|
        response.data.each do |data|
          data["row"].each do |id|
            yielder << CypherNode.new(self, id).wrapper
          end
        end
      end
    end

    def search_result_to_enumerable_first_column_without_tx(response)
      Enumerator.new do |yielder|
        response.data.each do |data|
          yielder << CypherNode.new(self, data[0]).wrapper
        end
      end
  end

    def map_column(key, map, data)
      case map[key]
        when :node
          CypherNode.new(self, data).wrapper
        when :rel, :relationship
          CypherRelationship.new(self, data)
        else
          data
      end
    end


    def search_result_to_enumerable(response, ret, map)
      return [] unless response.data

      if (ret.size == 1)
        Enumerator.new do |yielder|
          response.data.each do |data|
            yielder << map_column(key, map, data[0])
          end
        end

      else
        Enumerator.new do |yielder|
          response.data.each do |data|
            hash = {}
            ret.each_with_index do |key, i|
              hash[key] = map_column(key, map, data[i])
            end
            yielder << hash
          end
        end
      end
    end
  end
end
