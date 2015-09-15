module Neo4j
  module Core
    class Node
      def initialize(id, labels, properties)
        @id = id
        @labels = labels.map(&:to_sym)
        @properties = properties
      end
    end
  end
end