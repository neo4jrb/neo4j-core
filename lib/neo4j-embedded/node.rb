module Neo4j::Embedded
  class Node
    class << self
      # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
      def extend_java_class(java_clazz)
        java_clazz.class_eval do
          include Neo4j::Core::Property
          extend Neo4j::Core::TxMethods

          # TODO move
          def _set_db(db)
            @_database = db
          end

          def exist?
            @_database.node_exist?(self)
          end

          def props
            property_keys.inject({}) do |ret, key|
              ret[key] = get_property(key)
              ret
            end
          end

          def del
            # TODO _rels.each { |r| r.del }
            delete
            nil
          end
          tx_methods :del

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
