module Neo4j::Server
  class CypherMapping
    def create_node(props, labels)
      Neo4j::Cypher.query { node.new(props, *labels).neo_id }.to_s
    end

    def delete_node(id)
      Neo4j::Cypher.query { node(id).del}.to_s
    end

    def load_node(id)
      Neo4j::Cypher.query { node(id) }.to_s
    end

    def create_index(label, properties)
      "CREATE INDEX ON :`#{label}`(#{properties.join(',')})"
    end

    def drop_index(label, property)
      "DROP INDEX ON :`#{label}`(#{property})"
    end

    def remove_property(node_id, key)
      Neo4j::Cypher.query{node(node_id)[key]=:NULL}.to_s
    end

    def set_property(node_id, key,value)
      Neo4j::Cypher.query{node(node_id)[key]=value}.to_s
    end

    def get_property(node_id, key)
      Neo4j::Cypher.query{node(node_id)[key]}.to_s
    end

    def find_nodes_with_index(label_name, key, value)
      <<-CYPHER
        MATCH (n:`#{label_name}`)
        USING INDEX n:`#{label_name}`(#{key})
        WHERE n.#{key} = '#{value}'
        RETURN ID(n)
      CYPHER
    end

    def find_all_nodes(label_name)
      "MATCH (n:`#{label_name}`) RETURN ID(n)"
    end
  end
end