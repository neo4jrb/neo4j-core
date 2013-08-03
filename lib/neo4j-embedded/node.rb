module Neo4j::Embedded
  class Node
    class << self
      # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
      def extend_java_class(java_clazz)
        java_clazz.class_eval do
          include Neo4j::Embedded::Property

          # TODO move
          def _set_db(db)
            @_database = db
          end

          def exist?
            @_database.node_exist?(self)
          end

          def class
            Neo4j::Node
          end
          #include Neo4j::Core::Label
          #include Neo4j::Core::Wrapper
        end
      end
    end

    extend_java_class(Java::OrgNeo4jKernelImplCore::NodeProxy)
  end

end
