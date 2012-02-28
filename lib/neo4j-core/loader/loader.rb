module Neo4j
  module Core

    module Loader
      # Same as {Neo4j::Node#exist?} or {Neo4j::Relationship#exist?}
      # @return[true, false] if the node exists in the database
      def exist?
        Neo4j::Node.exist?(self)
      end

    end
  end
end
