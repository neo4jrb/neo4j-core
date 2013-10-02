module Neo4j
  class Node

    include PropertyContainer
    include EntityEquality

    # @abstract
    def create_rel(type, other_node, props = nil)
      raise 'not implemented'
    end

    # @abstract
    def rels(spec = nil)
      raise 'not implemented'
    end

    # @abstract
    def add_label(*labels)
      raise 'not implemented'
    end

    # @abstract
    def exist?
      raise 'not implemented'
    end

    # @abstract
    def labels
      raise 'not implemented'
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

      def find_nodes(label, value=nil, db = Neo4j::Database.instance)
        db.find_nodes(label, value)
      end
    end
  end

end