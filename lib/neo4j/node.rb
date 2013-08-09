module Neo4j
  class Node

    include Properties

    # @abstract
    def create_rel(type, other_node, props = nil)

    end

    def add_label(*labels)
    end

    def exist?
    end

    class << self
      def create(props=nil, *labels_or_db)
        db = Neo4j::Core::ArgumentHelper.db(labels_or_db)
        db.create_node(props, labels_or_db)
      end

      def load(neo_id, db = Neo4j::Database.instance)
        db.load_node(neo_id)
      end

      # Checks if the given entity node or entity id (Neo4j::Node#neo_id) exists in the database.
      # @return [true, false] if exist
      def exist?(entity_or_entity_id)
        db.node_exist?(neo_id)
      end
    end
  end

end