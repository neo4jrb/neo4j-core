module Neo4j
  module Core
    class Path
      attr_reader :nodes, :relationships, :directions

      include Wrappable

      def initialize(nodes, relationships, directions)
        @nodes = nodes
        @relationships = relationships
        @directions = directions
      end
    end
  end
end
