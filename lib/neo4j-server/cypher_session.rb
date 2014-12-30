module Neo4j::Server

  # Plugin
  Neo4j::Session.register_db(:server_db) do |*url_opts|
    Neo4j::Server::CypherSession.open(*url_opts)
  end

  class CypherSession < Neo4j::Session
    include Resource
    include Neo4j::Core::CypherTranslator

    alias_method :super_query, :query
    attr_reader :connection, :auth

    def initialize(data_url, connection, auth_obj = nil)
      @connection = connection
      @auth = auth_obj if auth_obj
      Neo4j::Session.register(self)
      initialize_resource(data_url)
      Neo4j::Session._notify_listeners(:session_available, self)
    end

    # @param [Hash] params could be empty or contain basic authentication user and password
    # @return [Faraday]
    # @see https://github.com/lostisland/faraday
    def self.create_connection(params)
      init_params = params[:initialize] && params.delete(:initialize)
      conn = Faraday.new(init_params) do |b|
        b.request :basic_auth, params[:basic_auth][:username], params[:basic_auth][:password] if params[:basic_auth]
        b.request :json
        # b.response :logger
        b.response :json, content_type: 'application/json'
        # b.use Faraday::Response::RaiseError
        b.use Faraday::Adapter::NetHttpPersistent
        # b.adapter  Faraday.default_adapter
      end
      conn.headers = {'Content-Type' => 'application/json', 'User-Agent' => ::Neo4j::Session.user_agent_string}
      conn
    end

    # Opens a session to the database
    # @see Neo4j::Session#open
    #
    # @param [String] endpoint_url - the url to the neo4j server, defaults to 'http://localhost:7474'
    # @param [Hash] params faraday params, see #create_connection or an already created faraday connection
    def self.open(endpoint_url = nil, params = {})
      extract_basic_auth(endpoint_url, params)
      connection = params[:connection] || create_connection(params)
      url = endpoint_url || 'http://localhost:7474'
      auth_obj = CypherAuthentication.new(url, connection, params)
      auth_obj.authenticate
      response = connection.get(url)
      fail "Server not available on #{url} (response code #{response.status})" unless response.status == 200
      establish_session(response.body, connection, auth_obj)
    end

    def self.establish_session(root_data, connection, auth_obj)
      data_url = root_data['data']
      data_url << '/' unless data_url.nil? || data_url.end_with?('/')
      CypherSession.new(data_url, connection, auth_obj)
    end

    def self.extract_basic_auth(url, params)
      return unless url && URI(url).userinfo
      params[:basic_auth] = {
        username: URI(url).user,
        password: URI(url).password
      }
    end

    private_class_method :extract_basic_auth

    def db_type
      :server_db
    end

    def to_s
      "#{self.class} url: '#{@resource_url}'"
    end

    def inspect
      "#{self} version: '#{version}'"
    end

    def version
      resource_data ? resource_data['neo4j_version'] : ''
    end

    def initialize_resource(data_url)
      response = @connection.get(data_url)
      expect_response_code(response, 200)
      data_resource = response.body
      fail "No data_resource for #{response.body}" unless data_resource
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
        wrap_resource('transaction', CypherTransaction, :post, @connection)
      end
      Neo4j::Transaction.current
    end

    def create_node(props = nil, labels = [])
      id = _query_or_fail(cypher_string(labels, props), true, cypher_prop_list(props))
      value = props.nil? ? id : {'id' => id, 'metadata' => {'labels' => labels}, 'data' => props}
      CypherNode.new(self, value)
    end

    def load_node(neo_id)
      load_entity(CypherNode, _query("MATCH (n) WHERE ID(n) = #{neo_id} RETURN n"))
    end

    def load_relationship(neo_id)
      load_entity(CypherRelationship, _query("MATCH (n)-[r]-() WHERE ID(r) = #{neo_id} RETURN r"))
    end

    def load_entity(clazz, cypher_response)
      return nil if cypher_response.data.nil? || cypher_response.data[0].nil?
      data  = if cypher_response.is_transaction_response?
                cypher_response.rest_data_with_id
              else
                cypher_response.first_data
              end

      if cypher_response.error?
        cypher_response.raise_error
      elsif cypher_response.error_msg =~ /not found/  # Ugly that the Neo4j API gives us this error message
        return nil
      else
        clazz.new(self, data)
      end
    end

    def create_label(name)
      CypherLabel.new(self, name)
    end

    def uniqueness_constraints(label)
      schema_properties("#{@resource_url}schema/constraint/#{label}/uniqueness")
    end

    def indexes(label)
      schema_properties("#{@resource_url}schema/index/#{label}")
    end

    def schema_properties(query_string)
      response = @connection.get(query_string)
      expect_response_code(response, 200)
      {property_keys: response.body.map { |row| row['property_keys'].map(&:to_sym) }}
    end

    def find_all_nodes(label_name)
      search_result_to_enumerable_first_column(_query_or_fail("MATCH (n:`#{label_name}`) RETURN ID(n)"))
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
        query, params = args[0, 2]
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

    def _query_or_fail(q, single_row = false, params = nil)
      response = _query(q, params)
      response.raise_error if response.error?
      single_row ? response.first_data : response
    end

    def _query_entity_data(q, id = nil, params = nil)
      response = _query(q, params)
      response.raise_error if response.error?
      response.entity_data(id)
    end

    def _query(q, params = nil)
      # puts "q #{q}"
      curr_tx = Neo4j::Transaction.current
      if curr_tx
        curr_tx._query(q, params)
      else
        url = resource_url('cypher')
        q = params.nil? ? {'query' => q} : {'query' => q, 'params' => params}
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
          data['row'].each do |id|
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
      if map[key] == :node
        CypherNode.new(self, data).wrapper
      elsif map[key] == :rel || map[:key] || :relationship
        CypherRelationship.new(self, data)
      else
        data
      end
    end
  end
end
