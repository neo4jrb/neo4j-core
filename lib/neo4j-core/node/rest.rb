module Neo4j
  module Node
    class Rest
      attr_reader :session, :id

      def initialize(node, session)
        @session = session # Set the session
        @node = node # Set the node
        @id = node["self"].split('/').last # Set the id
      end

      # Properties
      def [](property)
        property = property.to_s
        begin
          @session.neo.get_node_properties(@node, [property])[property]
        rescue Neography::NoSuchPropertyException => e
          nil
        end
      end

      def []=(property, value)
        if value.nil?
          begin
            @session.neo.remove_node_properties(@node, property.to_s)
          rescue Neography::NoSuchPropertyException => e
            return nil
          end
        else
          @session.neo.set_node_properties @node, property.to_s => value
        end
        return value
      end

      def reset(attributes)
        @session.neo.reset_node_properties(@node, attributes)
      end
    end
  end
end