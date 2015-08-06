module Neo4j
  module Core
    module GraphJSON
      def self.to_graph_json(objects)
        nodes = {}
        edges = {}

        objects.each do |object|
          case object
          when Neo4j::ActiveNode, Neo4j::Server::CypherNode
            nodes[object.neo_id] = {
              id: object.neo_id,
              labels: (object.is_a?(Neo4j::ActiveNode) ? [object.class.name] : object.labels),
              properties: object.attributes
            }
          when Neo4j::ActiveRel, Neo4j::Server::CypherRelationship
            edges[[object.start_node.neo_id, object.end_node.neo_id]] = {
              source: object.start_node.neo_id,
              target: object.end_node.neo_id,
              type: object.rel_type,
              properties: object.props
            }
          else
            fail "Invalid value found: #{object.inspect}"
          end
        end

        {
          nodes: nodes.values,
          edges: edges.values
        }.to_json
      end
    end
  end
end
