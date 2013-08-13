module Neo4j::Embedded
  class Node
    class << self
      # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
      def extend_java_class(java_clazz)
        java_clazz.class_eval do
          include Neo4j::Core::Property
          extend Neo4j::Core::TxMethods

          def exist?
            !!graph_database.get_node_by_id(neo_id)
          rescue Java::OrgNeo4jGraphdb.NotFoundException
            nil
          end
          tx_methods :exist?

          def props
            property_keys.inject({}) do |ret, key|
              ret[key] = get_property(key)
              ret
            end
          end
          tx_methods :props

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
