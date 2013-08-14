module Neo4j::Embedded
  class Node
    class << self
      # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
      def extend_java_class(java_clazz)
        java_clazz.class_eval do
          include Neo4j::Core::Property
          include Neo4j::EntityEquality
          extend Neo4j::Core::TxMethods

          def exist?
            !!graph_database.get_node_by_id(neo_id)
          rescue Java::OrgNeo4jGraphdb.NotFoundException
            nil
          end
          tx_methods :exist?

          def del
            # TODO _rels.each { |r| r.del }
            delete
            nil
          end
          tx_methods :del

          def create_rel(type, other_node, props = nil)
            rel = create_relationship_to(other_node, ToJava.type_to_java(type))
            props.each_pair { |k, v| rel[k] = v } if props
            rel
          end
          tx_methods :create_rel

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
