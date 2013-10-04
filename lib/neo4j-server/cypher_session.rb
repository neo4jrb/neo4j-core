module Neo4j::Server
  class CypherSession < Neo4j::Session
    include Resource

    attr_reader :cypher_mapping

    def initialize(data_url, cypher_mapping)
      response = HTTParty.get(data_url)
      expect_response_code(response,200)

      @cypher_mapping = cypher_mapping
      data_resource = JSON.parse(response.body)

      # store the resource data
      init_resource_data(data_resource, data_url)
      Neo4j::Session.register(self)
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
      cypher_response = _query(@cypher_mapping.create_node(props, labels))
      id = cypher_response.first_data
      CypherNode.new(self, id)
    end

    def load_node(neo_id)
      cypher_response = _query(@cypher_mapping.load_node(neo_id))
      if (!cypher_response.error?)
        CypherNode.new(self, neo_id)
      elsif (cypher_response.error_status == 'EntityNotFoundException')
        return nil
      else
        cypher_response.raise_error
      end
    end

    def create_label(name)
      CypherLabel.new(self, name)
    end

    def query(*params, &query_dsl)
      q = Neo4j::Cypher.query(*params, &query_dsl).to_s
      _query(q)
    end

    def _query(q, params=nil)
      curr_tx = Neo4j::Transaction.current
      if (curr_tx)
        raise "Params not supported" if params # TODO
        curr_tx._query(q)
      else
        url = resource_url('cypher')
        q = params ? {query: q} : {query: q, params: params}
        response = HTTParty.post(url, headers: resource_headers, body: q.to_json)
        CypherResponse.create_with_no_tx(response)
      end
    end

  end
end