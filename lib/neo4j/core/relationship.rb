module Neo4j
  module Core
    class Relationship
      def initialize(id, type, properties)
        @id = id
        @type = type.to_sym
        @properties = properties
      end
    end
  end
end