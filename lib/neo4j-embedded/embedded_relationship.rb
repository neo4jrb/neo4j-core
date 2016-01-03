module Neo4j
  module Embedded
    class EmbeddedRelationship
      MARSHAL_INSTANCE_VARIABLES = []

      class << self
        if !Neo4j::Core::Config.using_new_session?
          Java::OrgNeo4jKernelImplCore::RelationshipProxy.class_eval do
            include Neo4j::Embedded::Property
            include Neo4j::EntityEquality
            include Neo4j::Relationship::Wrapper
            include Neo4j::Core::ActiveEntity
            extend Neo4j::Core::TxMethods

            alias_method :_other_node, :getOtherNode

            def exist?
              !!graph_database.get_relationship_by_id(neo_id)
            rescue Java::OrgNeo4jGraphdb.NotFoundException
              false
            end
            tx_methods :exist?

            def inspect
              "EmbeddedRelationship neo_id: #{neo_id}"
            end

            def start_node
              _start_node.wrapper
            end
            tx_methods :start_node
            alias_method :_start_node_id, :start_node
            tx_methods :_start_node_id

            def _start_node
              getStartNode
            end

            def rel_type
              @_rel_type ||= _rel_type
            end

            def _rel_type
              getType.name.to_sym
            end
            tx_methods :rel_type

            def del
              delete
            end
            tx_methods :del
            tx_methods :delete

            alias_method :destroy, :del
            tx_methods :destroy

            def other_node(n)
              _other_node(n.neo4j_obj).wrapper
            end
            tx_methods :other_node

            def end_node
              _end_node.wrapper
            end
            tx_methods :end_node
            alias_method :_end_node_id, :end_node
            tx_methods :_end_node_id

            def _end_node
              getEndNode
            end
          end
        end
      end
    end
  end
end
