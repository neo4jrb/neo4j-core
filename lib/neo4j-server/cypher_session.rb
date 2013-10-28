module Neo4j::Server

  # Plugin
  Neo4j::Session.register_db(:server_db) do |endpoint_url|
    response = HTTParty.get(endpoint_url)
    raise "Server not available on #{endpoint_url} (response code #{response.code})" unless response.code == 200
    root_data = JSON.parse(response.body)
    Neo4j::Server::CypherSession.new(root_data['data'], CypherMapping.new)
  end

  class CypherSession < Neo4j::Session
    include Resource

    alias_method :super_query, :query

    def initialize(data_url, cypher_mapping)
      @cypher_mapping = cypher_mapping
      Neo4j::Session.register(self)
      initialize_resource(data_url)
    end

    def initialize_resource(data_url)
      response = HTTParty.get(data_url)
      expect_response_code(response,200)
      data_resource = JSON.parse(response.body)

      # store the resource data
      init_resource_data(data_resource, data_url)
    end

    def cypher_for(method, *args)
      @cypher_mapping.send(method, *args)
    end

    def query_cypher_for(method, *args)
      _query(cypher_for(method, *args))
    end

    def close
      super
      Neo4j::Transaction.unregister_current
    end

    def begin_tx
      tx = wrap_resource(self, 'transaction', CypherTransaction, nil, :post)
      Thread.current[:neo4j_curr_tx] = tx
      tx
    end

    def create_node(props=nil, labels=[])
      cypher_response = query_cypher_for(:create_node, props, labels)
      CypherNode.new(self, cypher_response.first_data)
    end

    def load_node(neo_id)
      cypher_response = query_cypher_for(:load_node, neo_id)
      if (!cypher_response.error?)
        CypherNode.new(self, neo_id)
      elsif (cypher_response.error_status == 'EntityNotFoundException')
        return nil
      else
        cypher_response.raise_error
      end
    end

    def load_relationship(neo_id)
      cypher_response = query_cypher_for(:load_relationship, neo_id)
      if (!cypher_response.error?)
        CypherRelationship.new(self, neo_id)
      elsif (cypher_response.error_msg =~ /not found/)  # Ugly that the Neo4j API gives us this error message
        return nil
      else
        cypher_response.raise_error
      end
    end

    def create_label(name)
      CypherLabel.new(self, name)
    end

    def indexes(label)
      response = HTTParty.get("#{@resource_url}schema/index/#{label}")
      expect_response_code(response, 200)
      data_resource = JSON.parse(response.body)

      property_keys = data_resource.map do |row|
        row['property-keys'].map(&:to_sym)
      end

      {
          property_keys: property_keys
      }
    end

    def find_all_nodes(label_name)
      response = query_cypher_for(:find_all_nodes, label_name)
      response.raise_error if response.error?
      search_result_to_enumerable(response)
    end

    def find_nodes(label_name, key,value)
      response = query_cypher_for(:find_nodes_with_index, label_name, key, value)
      response.raise_error if response.error?
      search_result_to_enumerable(response)
    end

    def query(*params, &query_dsl)
      result = super
      if result.error?
        raise Neo4j::Session::CypherError.new(result.error_msg, result.error_code, result.error_status)
      end
      result.to_hash_enumeration
    end

    # TODO remove this function and do not use cypher DSL internally
    def _query_internal(*params, &query_dsl)
      super_query(*params, &query_dsl)
    end

    def _query(q, params=nil)
      curr_tx = Neo4j::Transaction.current
      if (curr_tx)
        raise "Params not supported" if params # TODO
        curr_tx._query(q)
      else
        url = resource_url('cypher')
        q = params.nil? ? {query: q} : {query: q, params: params}
        response = HTTParty.post(url, headers: resource_headers, body: q.to_json)
        CypherResponse.create_with_no_tx(response)
      end
    end

    private

    def search_result_to_enumerable(response)
      return [] unless response.data
      Enumerator.new do |yielder|
        response.data.each do |data|
          yielder << CypherNode.new(@session, data[0])
        end
      end
    end




  end
end