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
        properties = props
        number_of_results = keys.length
        keys = keys.select { |k| properties[k] }
        properties = @session.neo.get_node_properties(@node, keys)
        result = Array.new(number_of_results)
        for i in 0...keys.length
          result[i] = properties[keys[i]]
        end
        if number_of_results == 1
          result.first
        else
          result
        end
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def []=(*keys, values)
        values = [values].flatten
        keys.map!(&:to_s)
        properties = props
        attributes = Hash[keys.zip values].select { |k| properties[k] }
        nil_values = lambda { |_, v| v.nil? }
        keys_to_delete = attributes.select(&nil_values).keys
        attributes.delete_if(&nil_values)
        @session.neo.remove_node_properties(@node, keys_to_delete)
        properties = @session.neo.set_node_properties(@node, attributes)
        result = keys.map { |key| properties[key] } # Return the result in the correct order
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def props
        @session.neo.get_node_properties(@node) || {}
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def props=(attributes)
        attributes = attributes.delete_if { |_, value| value.nil? }
        @session.neo.reset_node_properties(@node, attributes)
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def delete
        @session.neo.delete_node @node
        @node = @session = nil
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def destroy
        @session.neo.delete_node! @node
        @node = @session = nil
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
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
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      private
        def raise_doesnt_exist_anymore_error(e)
          if @session.nil?
            raise StandardError.new("Node[#{@id}] does not exist anymore!") 
          else
            raise e
          end
        end
    end
  end
end