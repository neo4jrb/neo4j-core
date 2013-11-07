module Neo4j

  module Core
    module Node

      # Delete the node and all its relationship.
      #
      # It might raise an exception if this method was called without a Transaction,
      # or if it failed to delete the node (it maybe was already deleted).
      #
      # If this method raise an exception you may also get an exception when the transaction finish.
      # This method is  defined in the  Java::OrgNeo4jKernel::impl.core.NodeProxy which is return by Neo4j::Node.new
      #
      # @return nil or raise an exception
      def del
        _rels.each { |r| r.del }
        delete
        nil
      end

      # This method can be used to access the none wrapped neo4j node/relationship java object.
      # Notice that this method is defined in the  Java::OrgNeo4jKernel::impl.core.NodeProxy or RelationshipProxy which is return by Neo4j::Node.new
      # @return the java node/relationship object representing this object unless it is already the java object.
      def _java_node
        self
      end

      # Same as Neo4j::Node#exist? or Neo4j::Relationship#exist?
      # @return [true, false] if the node exists in the database
      def exist?
        Neo4j::Node.exist?(self)
      end

      # Overrides the class so that the java object feels like a Ruby object.
      def class
        Neo4j::Node
      end
    end
  end
end