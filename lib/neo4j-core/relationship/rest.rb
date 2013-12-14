require "neo4j-core/property_container"

module Neo4j
  module Relationship
    class Rest
      include PropertyContainer::Rest
      attr_reader :session, :id, :start, :end, :nodes, :type
      
      def initialize(relationship, session)
        @relationship = relationship
        @session = session
        @id = @relationship["self"].split('/').last.to_i # Set the id
        @start = @session.load(@relationship["start"])
        @end = @session.load(@relationship["end"])
        @nodes = [@start, @end]
        @type  = @relationship["type"]
      end

      def other_node(node)
        case node
        when @start
          @end
        when @end
          @start
        else
          nil
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
       end


      def to_s
        "REST Relationship[#{@id}]"
      end

      def type
        @relationship["type"]
      end

      private
        def _get_properties(*keys)
          @session.neo.get_relationship_properties(@relationship, *keys)
        end

        def _set_properties(keys)
          @session.neo.set_relationship_properties(@relationship, keys)
        end

        def _reset_properties(attributes)
          @session.neo.reset_relationship_properties(@relationship, attributes)
        end

        def _remove_properties(keys_to_delete)
          @session.neo.remove_relationship_properties(@relationship, keys_to_delete)
        end

        def _set_private_vars_to_nil
          @relationship = @session = @start = @end = @nodes = nil
        end

        def _delete
          @session.neo.delete_relationship(@relationship)
        end

        def _destroy
          _delete
          @start.delete
          @end.delete
        end
    end
  end
end