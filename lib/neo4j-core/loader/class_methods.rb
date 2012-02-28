module Neo4j
  module Core

    module Loader

      module ClassMethods

        # Checks if the given entity node or entity id (Neo4j::Node#neo_id) exists in the database.
        # @return [true, false] if exist
        def exist?(entity_or_entity_id, db = Neo4j.started_db)
          id = entity_or_entity_id.kind_of?(Fixnum) ? entity_or_entity_id : entity_or_entity_id.id
          _load(id, db) != nil
        end

        # Loads a node or wrapped node given a native java node or an id.
        # If there is a Ruby wrapper for the node then it will create a Ruby object that will
        # wrap the java node (see Neo4j::NodeMixin).
        # To implement a wrapper you must implement a wrapper class method in the Neo4j::Node or Neo4j::Relationship.
        #
        # @return [Object, nil] If the node does not exist it will return nil otherwise the loaded node or wrapped node.
        def load(node_id, db = Neo4j.started_db)
          node = _load(node_id, db)
          node && node.wrapper
        end
      end

    end
  end
end