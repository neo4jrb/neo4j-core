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
      node_data = cypher_response.first_data

      if cypher_response.uncommited?
        CypherNodeUncommited.new(self, node_data)
      else
        url = node_data['self']
        CypherNode.new(self).init_resource_data(node_data,url)
      end
    end

    def load_node(neo_id)
      cypher_response = query { node(neo_id) }
      if (!cypher_response.error?)
        node_data = cypher_response.first_data
        url = node_data['self']
        cypher_node = CypherNode.new(self)
        cypher_node.init_resource_data(node_data,url)
        cypher_node
      elsif (cypher_response.exception == 'EntityNotFoundException')
        return nil
      else
        handle_response_error(cypher_response.response)
      end
    end

    def create_label(name)
      # TODO hard coded url, not available yet in server ???
      url = "#{@data_url}schema/index/#{name}"
      CypherLabel.new(self, url, name)
    end

  end
end