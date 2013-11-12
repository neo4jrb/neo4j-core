module Neo4j
  module Node
    class Rest
      attr_reader :session, :id

      def initialize(node, session)
        @session = session # Set the session
        @node = node # Set the node
        @id = node["self"].split('/').last # Set the id
      end

      def [](property)
        property = property.to_s
        @session.neo.get_node_properties(@node, [property])[property]
      end

      def []=(property, value)
        if value.nil?
          @session.neo.remove_node_properties(@node, property.to_s)
        else
          @session.neo.set_node_properties @node, property.to_s => value
        end
        return
      end
    end
  end
end