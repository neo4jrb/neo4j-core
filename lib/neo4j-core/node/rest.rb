module Neo4j
  module Node
    class Rest
      attr_reader :session, :id, :node

      def initialize(node, session)
        @session = session # Set the session
        @node = node # Set the node
        @id = node["self"].split('/').last.to_i # Set the id
      end

      def ==(node)
        @id == node.id
      end

      # Properties
      def [](*keys)
        keys.map!(&:to_s)
        begin
          props = @session.neo.get_node_properties(@node, keys)
          result = keys.map { |key| props[key] } # Return the result in the correct order
        rescue Neography::NoSuchPropertyException
          if keys.length == 1
            nil
          else
            []
          end
        end
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def []=(*keys, values)
        values = [values].flatten
        keys.map!(&:to_s)
        attributes = Hash[keys.zip values]
        keys_to_delete = attributes.delete_if { |k, v| v.nil? }.keys
        begin
          @session.neo.remove_node_properties(@node, keys_to_delete)
          props = @session.neo.set_node_properties(@node, attributes)
          result = keys.map { |key| props[key] } # Return the result in the correct order
        rescue Neography::NoSuchPropertyException
          nil
        end
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

      def create_rel_to(end_node, type, attributes = {})
        if @session != end_node.session
          msg = "Cannot create a relationship with a node from another session\n" +
                "Start Node Session: #{@session.url}\n" +
                "End Node Session: #{end_node.session.url}"
          raise msg
        end
        attributes = attributes.delete_if { |key, value| value.nil? }
        neo_rel = @session.neo.create_relationship(type, @node, end_node.node, attributes)
        return nil if neo_rel.nil?
        rel = Relationship::Rest.new(neo_rel, @session)
        rel.props = attributes
        rel
      end

      private
        def raise_doesnt_exist_anymore_error
          raise StandardError.new("Node[#{@id}] does not exist anymore!")
        end
    end
  end
end