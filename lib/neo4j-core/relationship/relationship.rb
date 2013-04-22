module Neo4j
  module Core
    module Relationship

      # Same as Java::OrgNeo4jGraphdb::Relationship#getEndNode
      # @see http://api.neo4j.org/1.6.1/org/neo4j/graphdb/Relationship.html#getEndNode()
      def _end_node
        get_end_node
      end

      # Same as Java::OrgNeo4jGraphdb::Relationship#getStartNode
      # @see http://api.neo4j.org/1.6.1/org/neo4j/graphdb/Relationship.html#getStartNode()
      def _start_node
        get_start_node
      end
      
      # Same as Java::OrgNeo4jGraphdb::Relationship#getNodes
      # @see http://api.neo4j.org/1.6.1/org/neo4j/graphdb/Relationship.html#getNodes()
      def _nodes
        get_nodes
      end

      # Same as Java::OrgNeo4jGraphdb::Relationship#getOtherNode
      # @see http://api.neo4j.org/1.6.1/org/neo4j/graphdb/Relationship.html#getOtherNode()
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
        # Just for documentation purpose, it is aliased from end_node_wrapper
      end

      # @private
      def end_node_wrapper
        _end_node.wrapper
      end

      # Same as Java::OrgNeo4jGraphdb::Relationship#getStartNode but returns the wrapper for it (if it exist)
      # @see Neo4j::Node#wrapper
      def start_node
        # Just for documentation purpose, it is aliased from start_node_wrapper
      end

      # @private
      def start_node_wrapper
        _start_node.wrapper
      end

      # A convenience operation that, given a node that is attached to this relationship, returns the other node.
      # For example if node is a start node, the end node will be returned, and vice versa.
      # This is a very convenient operation when you're manually traversing the node space by invoking one of the #rels
      # method on a node. For example, to get the node "at the other end" of a relationship, use the following:
      #
      # @example
      #   end_node = node.rels.first.other_node(node)
      #
      # @raise This operation will throw a runtime exception if node is neither this relationship's start node nor its end node.
      #
      # @param [Neo4j::Node] node the node that we don't want to return
      # @return [Neo4j::Node] the other node wrapper
      # @see #_other_node
      def other_node(node)
        _other_node(node._java_node).wrapper
      end


      # same as #_java_rel
      # Used so that we have same method for both relationship and nodes
      def _java_entity
        self
      end

      # @return self
      def _java_rel
        self
      end

      # @return [true, false] if the relationship exists
      def exist?
        Neo4j::Relationship.exist?(self)
      end

      # Returns the relationship name
      #
      # @example
      #   a = Neo4j::Node.new
      #   a.outgoing(:friends) << Neo4j::Node.new
      #   a.rels.first.rel_type # => :friends
      # @return [Symbol] the type of the relationship
      def rel_type
        getType().name().to_sym
      end

      def class
        Neo4j::Relationship
      end


      alias_method :start_node, :start_node_wrapper
      alias_method :end_node, :end_node_wrapper

    end
  end
end
