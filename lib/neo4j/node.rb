module Neo4j
  class Node

    # the valid values on a property, and arrays of those.
    VALID_PROPERTY_VALUE_CLASSES = Set.new([Array, NilClass, String, Float, TrueClass, FalseClass, Fixnum])

    # Only documentation here
    def [](key)
      get_property(key)
    end


    def []=(key,value)
      unless valid_property?(value)
        raise Neo4j::InvalidPropertyException.new("Not valid Neo4j Property value #{value.class}, valid: #{Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.to_a.join(', ')}")
      end

      if value.nil?
        remove_property(key)
      else
        set_property(key,value)
      end
    end

    def add_label(*labels)
    end

    def exist?
    end

    # @param [Object] value the value we want to check if it's a valid neo4j property value
    # @return [True, False] A false means it can't be persisted.
    def valid_property?(value)
      VALID_PROPERTY_VALUE_CLASSES.include?(value.class)
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