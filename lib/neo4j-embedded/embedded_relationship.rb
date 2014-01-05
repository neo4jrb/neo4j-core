module Neo4j::Embedded
  class EmbeddedRelationship
    class << self
      # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
      def extend_java_class(java_clazz)
        java_clazz.class_eval do
          include Neo4j::Embedded::Property
          include Neo4j::EntityEquality
          include Neo4j::Relationship::Wrapper
          extend Neo4j::Core::TxMethods

          alias_method :_other_node, :getOtherNode

          def exist?
            !!graph_database.get_relationship_by_id(neo_id)
          rescue Java::OrgNeo4jGraphdb.NotFoundException
            nil
          end
          tx_methods :exist?

          def start_node
            getStartNode.wrapper
          end
          tx_methods :start_node

          def del
            delete
          end
          tx_methods :del

          def other_node(n)
            _other_node(n.neo4j_obj).wrapper
          end

          def end_node
            getEndNode.wrapper
          end
          tx_methods :end_node

        end
      end
    end

    extend_java_class(Java::OrgNeo4jKernelImplCore::RelationshipProxy)

  end


end
