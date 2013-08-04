module Neo4j::Server
  class CypherDatabase < RestDatabase

    def shutdown()
      raise "Can't shutdown Neo4j::Server database (try the unregister method instead)"
    end

    def unregister
      Neo4j::Database.unregister_instance(nil)
    end

    def create_node(props=nil, labels=[])
      cypher_response = query { node.new(props, *labels) }
      expect_response_code(cypher_response, 200)
      node_data = cypher_response['data'][0][0]
      url = node_data['self']
      cypher_node = CypherNode.new(self)
      cypher_node.init_resource_data(node_data,url)
      cypher_node
    end

    def load_node(neo_id)
      cypher_response = query { node(neo_id) }
      if (cypher_response.code == 200)
        node_data = cypher_response['data'][0][0]
        url = node_data['self']
        cypher_node = CypherNode.new(self)
        cypher_node.init_resource_data(node_data,url)
        cypher_node
      else
        return nil if response_exception(cypher_response) == 'EntityNotFoundException'
        raise "Unknown response, #{cypher_response.code}, #{cypher_response.body}"
      end

    end
  end
end