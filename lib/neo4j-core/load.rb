module Neo4j
  module Core

    # === Mixin responsible for loading Ruby wrappers for Neo4j Nodes and Relationship.
    #
    module Load
      def wrapper(entity) # :nodoc:
        entity
      end

      # Checks if the given entity (node/relationship) or entity id (#neo_id) exists in the database.
      def exist?(entity_or_entity_id, db = Neo4j.started_db)
        id = entity_or_entity_id.kind_of?(Fixnum) ? entity_or_entity_id : entity_or_entity_id.id
        _load(id, db) != nil
      end
    end
  end
end