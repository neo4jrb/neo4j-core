module Neo4j::Server
  class CypherMapping
    def create_node(props, *labels)
      Neo4j::Cypher.query { node.new(props, *labels).neo_id }.to_s
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
  end
end