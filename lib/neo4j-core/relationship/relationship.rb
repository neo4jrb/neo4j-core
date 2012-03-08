module Neo4j
  module Core
    module Relationship

      # Same as Java::OrgNeo4jGraphdb::Relationship#getEndNode
      def _end_node
        get_end_node
      end

      # Same as Java::OrgNeo4jGraphdb::Relationship#getStartNode
      def _start_node
        get_start_node
      end

      # Same as Java::OrgNeo4jGraphdb::Relationship#getOtherNode
      def _other_node(node)
        get_other_node(node)
      end

      # Deletes the relationship between the start and end node
      # May raise an exception if delete was unsuccessful.
      #
      # @return [nil]
      def del
        delete
      end

      # Same as Java::OrgNeo4jGraphdb::Relationship#getEndNode but returns the wrapper for it (if it exist)
      # @see Neo4j::Node#wrapper
      def end_node
        getEndNode.wrapper
      end

      # Same as Java::OrgNeo4jGraphdb::Relationship#getStartNode but returns the wrapper for it (if it exist)
      # @see Neo4j::Node#wrapper
      def start_node
        getStartNode.wrapper
      end

      # A convenience operation that, given a node that is attached to this relationship, returns the other node.
      # For example if node is a start node, the end node will be returned, and vice versa.
      # This is a very convenient operation when you're manually traversing the node space by invoking one of the #rels
      # method on a node. For example, to get the node "at the other end" of a relationship, use the following:
      #
      #   end_node = node.rels.first.other_node(node)
      #
      # This operation will throw a runtime exception if node is neither this relationship's start node nor its end node.
      #
      # === Parameters
      #
      # node :: the node that we don't want to return
      def other_node(node)
        getOtherNode(node._java_node).wrapper
      end


      # same as _java_rel
      # Used so that we have same method for both relationship and nodes
      def wrapped_entity
        self
      end

      def _java_rel
        self
      end


      # Returns true if the relationship exists
      def exist?
        Neo4j::Relationship.exist?(self)
      end

      # Loads the Ruby wrapper for this node
      # If there is no _classname property for this node then it will simply return itself.
      # Same as Neo4j::Node.load_wrapper(node)
      def wrapper
        self.class.wrapper(self)
      end


      # Returns the relationship name
      #
      # ==== Example
      #   a = Neo4j::Node.new
      #   a.outgoing(:friends) << Neo4j::Node.new
      #   a.rels.first.rel_type # => 'friends'
      #
      def rel_type
        getType().name()
      end


      def class
        Neo4j::Relationship
      end


    end
  end
end
