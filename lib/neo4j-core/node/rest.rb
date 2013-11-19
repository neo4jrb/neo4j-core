module Neo4j
  module Node
    class Rest
      attr_reader :session, :id, :node

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
        raise_doesnt_exist_anymore_error
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
        raise_doesnt_exist_anymore_error
      end

      def reset(attributes)
        @session.neo.reset_node_properties(@node, attributes)
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def delete
        @session.neo.delete_node @node
        @session = nil
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def destroy
        @session.neo.delete_node! @node
        @node = @session = nil
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def to_s
        "REST Node[#{@id}]"
      end

      def create_rel_to(end_node, name, attributes = {})
        neo_rel = @session.neo.create_relationship(name, @node, end_node.node)
        rel = Relationship::Rest.new(neo_rel, @session, self, @end_node, name)
        attributes = attributes.delete_if { |key, value| value.nil? }
        if rel.nil?
          nil
        else
          rel.props = attributes
        end
      end

      private
        def raise_doesnt_exist_anymore_error
          raise StandardError.new("Node[#{@id}] does not exist anymore!")
        end
    end
  end
end