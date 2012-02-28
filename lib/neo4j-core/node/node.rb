module Neo4j

  module Core
    module Node

      # Delete the node and all its relationship.
      #
      # It might raise an exception if this method was called without a Transaction,
      # or if it failed to delete the node (it maybe was already deleted).
      #
      # If this method raise an exception you may also get an exception when the transaction finish.
      # This method is  defined in the  org.neo4j.kernel.impl.core.NodeProxy which is return by Neo4j::Node.new
      #
      # @return nil or raise an exception
      def del #:nodoc:
        _rels.each { |r| r.del }
        delete
        nil
      end

      def _java_node
        self
      end

      def class
        Neo4j::Node
      end
    end
  end
end