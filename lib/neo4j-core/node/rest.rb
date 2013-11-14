module Neo4j
  module Node
    class Rest
      attr_reader :session, :id

      def initialize(node, session)
        @session = session # Set the session
        @node = node # Set the node
        @id = node["self"].split('/').last.to_i # Set the id
      end

      # Properties
      def [](property)
        property = property.to_s
        begin
          @session.neo.get_node_properties(@node, [property])[property]
        rescue Neography::NoSuchPropertyException
          nil
        end
      rescue NoMethodError
        raise StandardError.new("Node[#{@id}] does not exist anymore!")
      end

      def []=(property, value)
        if value.nil?
          begin
            @session.neo.remove_node_properties(@node, property.to_s)
          rescue Neography::NoSuchPropertyException
            return nil
          end
        else
          @session.neo.set_node_properties @node, property.to_s => value
        end
        value
      rescue NoMethodError
        raise StandardError.new("Node[#{@id}] does not exist anymore!")
      end

      def reset(attributes)
        @session.neo.reset_node_properties(@node, attributes)
      rescue NoMethodError
        raise StandardError.new("Node[#{@id}] does not exist anymore!")
      end

      def delete
        @session.neo.delete_node @node
        @node = @session = nil
      rescue NoMethodError
        raise StandardError.new("Node[#{@id}] does not exist anymore!")
      end

      def destroy
        @session.neo.delete_node! @node
        @node = @session = nil
      rescue NoMethodError
        raise StandardError.new("Node[#{@id}] does not exist anymore!")
      end

      def to_s
        "REST Node[#{@id}]"
      end
    end
  end
end