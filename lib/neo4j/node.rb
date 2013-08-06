module Neo4j
  class Node

    # TODO include Neo4j::Core::Property

    # the valid values on a property, and arrays of those.
    VALID_PROPERTY_VALUE_CLASSES = Set.new([Array, NilClass, String, Float, TrueClass, FalseClass, Fixnum])

    # Only documentation here
    def [](key)
    end

    def []=(key,value)
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

  #class Node
  #  # include these modules only for documentation purpose
  #  include Neo4j::Core::Property
  #  include Neo4j::Core::Label
  #  include Neo4j::Core::Wrapper
  #  extend Neo4j::Core::Initialize::ClassMethods
  #  extend Neo4j::Core::Wrapper::ClassMethods
  #
  #  class << self
  #    # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
  #    def extend_java_class(java_clazz)
  #      java_clazz.class_eval do
  #        include Neo4j::Core::Property
  #        include Neo4j::Core::Label
  #        include Neo4j::Core::Wrapper
  #      end
  #    end
  #  end
  #
  #  extend_java_class(Java::OrgNeo4jKernelImplCore::NodeProxy)
  #end

end