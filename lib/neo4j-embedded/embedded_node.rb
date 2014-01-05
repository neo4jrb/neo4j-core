module Neo4j::Embedded
  class RelsIterator
    include Enumerable
    extend Neo4j::Core::TxMethods

    def initialize(node, match)
      @node = node
      @match = match
    end

    def each(&block)
      @node._rels(@match).each {|r| block.call(r.wrapper)}
    end
    tx_methods :each

    def empty?
      first == nil
    end

  end

  class NodesIterator
    include Enumerable
    extend Neo4j::Core::TxMethods

    def initialize(node, match)
      @node = node
      @match = match
    end

    def each(&block)
      @node._rels(@match).each {|r| block.call(r.other_node(@node))}
    end
    tx_methods :each

    def empty?
      first == nil
    end

  end

  class EmbeddedNode
    class << self
      # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
      def extend_java_class(java_clazz)
        java_clazz.class_eval do
          include Neo4j::Embedded::Property
          include Neo4j::EntityEquality
          extend Neo4j::Core::TxMethods

          def exist?
            !!graph_database.get_node_by_id(neo_id)
          rescue Java::OrgNeo4jGraphdb.NotFoundException
            nil
          end
          tx_methods :exist?

          def labels
            _labels.iterator.map{|x| x.name.to_sym}
          end
          tx_methods :labels

          alias_method :_labels, :getLabels

          def del
            _rels.each { |r| r.del }
            delete
            nil
          end
          tx_methods :del

          def create_rel(type, other_node, props = nil)
            rel = create_relationship_to(other_node.neo4j_obj, ToJava.type_to_java(type))
            props.each_pair { |k, v| rel[k] = v } if props
            rel
          end
          tx_methods :create_rel


          def rels(match={})
            RelsIterator.new(self, match)
          end

          def nodes(match={})
            NodesIterator.new(self, match)
          end

          def node(match={})
            rel = _rel(match)
            rel && rel.other_node(self).wrapper
          end
          tx_methods :node

          def rel?(match={})
            _rels(match).has_next
          end
          tx_methods :rel?

          def rel(match={})
            _rel(match)
          end
          tx_methods :rel

          def _rel(match={})
            dir = match[:dir] || :both
            rel_type = match[:type]

            rel = if rel_type
                     get_single_relationship(ToJava.type_to_java(rel_type), ToJava.dir_to_java(dir))
                  else
                     iter = get_relationships(ToJava.dir_to_java(dir)).iterator
                     if (iter.has_next)
                       first = iter.next
                       raise "Expected to only find one relationship from node #{neo_id} matching #{match.inspect}" if iter.has_next
                       first
                     end
                   end

            between_id = match[:between] && match[:between].neo_id

            if (rel && between_id)
              rel.other_node(self).neo_id == between_id ? rel : nil
            else
              rel
            end
          end

          def _rels(match={})
            dir = match[:dir] || :both
            rel_type = match[:type]

            rels = if rel_type
              get_relationships(ToJava.type_to_java(rel_type), ToJava.dir_to_java(dir)).iterator
            else
              get_relationships(ToJava.dir_to_java(dir)).iterator
            end

            between_id = match[:between] && match[:between].neo_id

            if (between_id)
              rels.find_all{|r| r.end_node.neo_id == between_id || r.start_node.neo_id == between_id}
            else
              rels
            end

          end

          def class
            Neo4j::Node
          end

          include Neo4j::Node::Wrapper
        end
      end
    end

    extend_java_class(Java::OrgNeo4jKernelImplCore::NodeProxy)
  end

end
