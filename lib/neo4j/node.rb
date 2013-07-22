module Neo4j
  class Node

    # Only documentation here
    def [](key)
    end

    def []=(key,value)
    end

    class << self
      def new(props=nil, *label_or_db)
        driver = Neo4j::Database.instance.driver_for(Neo4j::Node)
        # TODO, db default args
        driver.create_node(props, label_or_db)
      end

      def load(neo_id, db = Neo4j::Database.instance)
        driver = db.driver_for(Neo4j::Node)
        driver.load(neo_id)
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