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

    def delete_rels(neo_id)
      "START n = node(#{neo_id}) MATCH n-[r]-() DELETE r"
    end

    def load_relationship(id)
      "START r=relationship(#{id}) RETURN r"
    end

    def delete_node(neo_id)
      "START n = node(#{neo_id}) DELETE n"
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

    def remove_rel_property(rel_id, key)
      Neo4j::Cypher.query{rel(rel_id)[key]=:NULL}.to_s
    end

    def set_rel_property(rel_id, key,value)
      Neo4j::Cypher.query{rel(rel_id)[key]=value}.to_s
    end

    def get_rel_property(rel_id, key)
      Neo4j::Cypher.query{rel(rel_id)[key]}.to_s
    end

    # to check if the rel still exists
    def get_same_rel_id(rel_id)
      Neo4j::Cypher.query{rel(rel_id).neo_id}.to_s
    end

    # to check if the node still exists
    def get_same_node_id(node_id)
      Neo4j::Cypher.query{node(node_id).neo_id}.to_s
    end

    def find_nodes_with_index(label_name, key, value)
      <<-CYPHER
        MATCH (n:`#{label_name}`)
        WHERE n.#{key} = '#{value}'
        RETURN ID(n)
      CYPHER
    end

    def find_all_nodes(label_name)
      "MATCH (n:`#{label_name}`) RETURN ID(n)"
    end

    def create_rels(start_node, end_node, type)
      Neo4j::Cypher.query { create_path { node(start_node) > rel(type).as(:r) > node(end_node) }; rel.as(:r).neo_id }.to_s
    end

    def create_rels_with_props(start_node, end_node, type, props)
      Neo4j::Cypher.query { create_path { node(start_node) > rel(type, props).as(:r) > node(end_node) }; rel.as(:r).neo_id }.to_s
    end

  end
end