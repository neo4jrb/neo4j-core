module Neo4j
  module Core
    # A module to make Neo4j::Node and Neo4j::Relationship work better together with neo4j.rb's Neo4j::ActiveNode and Neo4j::ActiveRel
    module ActiveEntity
      # @return true
      def persisted?
        true
      end
    end
  end
end
