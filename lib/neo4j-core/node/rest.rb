require "neo4j-core/property_container"

module Neo4j
  module Node
    class Rest
      include PropertyContainer
      attr_reader :session, :id, :node

      def initialize(node, session)
        @session = session # Set the session
        @node = node # Set the node
        @id = node["self"].split('/').last.to_i # Set the id
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
        _raise_doesnt_exist_anymore_error(e)
      end

      private
        def _get_properties(*keys)
          @session.neo.get_node_properties(@node, *keys)
        end

        def _set_properties(keys)
          @session.neo.set_node_properties(@node, keys)
        end

        def _reset_properties(attributes)
          @session.neo.reset_node_properties(@node, attributes)
        end

        def _remove_properties(keys_to_delete)
          @session.neo.remove_node_properties(@node, keys_to_delete)
        end

        def _set_private_vars_to_nil
          @node = @session = nil
        end

        def _delete
          @session.neo.delete_node(@node)
        end

        def _destroy
          @session.neo.delete_node!(@node)
        end
    end
  end
end