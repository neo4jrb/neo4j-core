require "neo4j-core/property_container"

module Neo4j
  module Node
    class Rest
      include PropertyContainer::Rest
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
        return nil if @session.url != end_node.session.url
        attributes.delete_if { |key, value| value.nil? }
        neo_rel = @session.neo.create_relationship(type, @node, end_node.node, attributes)
        return nil if neo_rel.nil?
        rel = Relationship::Rest.new(neo_rel, @session)
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      private
        def _get_properties(*keys)
          @session.neo.get_node_properties(@node, *keys)
        end

        def _reset_properties(attributes)
          @session.neo.reset_node_properties(@node, attributes)
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