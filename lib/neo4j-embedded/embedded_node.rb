module Neo4j
  module Embedded
    class RelsIterator
      include Enumerable
      extend Neo4j::Core::TxMethods

      MARSHAL_INSTANCE_VARIABLES = %i[@node @match]

      def initialize(node, match)
        @node = node
        ::Neo4j::Node.validate_match!(match)
        @match = match
      end

      def inspect
        'Enumerable<Neo4j::Relationship>'
      end

      def each
        @node._rels(@match).each { |r| yield(r.wrapper) }
      end
      tx_methods :each

      def empty?
        first.nil?
      end
    end

    class NodesIterator
      include Enumerable
      extend Neo4j::Core::TxMethods

      def initialize(node, match)
        @node = node
        @match = match
      end

      def inspect
        'Enumerable<Neo4j::Node>'
      end

      def each
        @node._rels(@match).each { |r| yield(r.other_node(@node)) }
      end
      tx_methods :each

      def empty?
        first.nil?
      end
    end

    class EmbeddedNode < Neo4j::Node
      class << self
        if !Neo4j::Core::Config.using_new_session?
          # This method is used to extend a Java Neo4j class so that it includes the same mixins as this class.
          Java::OrgNeo4jKernelImplCore::NodeProxy.class_eval do
            include Neo4j::Embedded::Property
            include Neo4j::EntityEquality
            include Neo4j::Core::ActiveEntity
            extend Neo4j::Core::TxMethods

            def inspect
              "EmbeddedNode neo_id: #{neo_id}"
            end

            def exist?
              !!graph_database.get_node_by_id(neo_id)
            rescue Java::OrgNeo4jGraphdb.NotFoundException
              false
            end
            tx_methods :exist?

            def labels
              _labels.iterator.map { |x| x.name.to_sym }
            end
            tx_methods :labels

            alias_method :_labels, :getLabels

            def _java_label(label_name)
              Java::OrgNeo4jGraphdb.DynamicLabel.label(label_name)
            end

            def _add_label(*label_name)
              label_name.each do |name|
                addLabel(_java_label(name))
              end
            end

            alias_method :add_label, :_add_label
            tx_methods :add_label

            def _remove_label(*label_name)
              label_name.each do |name|
                removeLabel(_java_label(name))
              end
            end

            alias_method :remove_label, :_remove_label
            tx_methods :remove_label

            def set_label(*label_names)
              label_as_symbols = label_names.map(&:to_sym)
              to_keep = labels & label_as_symbols
              to_remove = labels - to_keep
              _remove_label(*to_remove)
              to_add = label_as_symbols - to_keep
              _add_label(*to_add)
            end
            tx_methods :set_label

            def del
              _rels.each(&:del)
              delete
              nil
            end
            tx_methods :del
            tx_methods :delete

            alias_method :destroy, :del
            tx_methods :destroy

            def create_rel(type, other_node, props = nil)
              rel = create_relationship_to(other_node.neo4j_obj, ToJava.type_to_java(type))
              props.each_pair { |k, v| rel[k] = v } if props
              rel
            end
            tx_methods :create_rel


            def rels(match = {})
              RelsIterator.new(self, match)
            end

            def nodes(match = {})
              NodesIterator.new(self, match)
            end

            def node(match = {})
              rel = _rel(match)
              rel && rel.other_node(self).wrapper
            end
            tx_methods :node

            def rel?(match = {})
              _rels(match).has_next
            end
            tx_methods :rel?

            def rel(match = {})
              _rel(match)
            end
            tx_methods :rel

            def _rel(match = {})
              dir, rel_type, between_id = _parse_match(match)

              rel = if rel_type
                      get_single_relationship(rel_type, dir)
                    else
                      _get_single_relationship_by_dir(dir)
                    end

              rel if !(rel && between_id) || rel.other_node(self).neo_id == between_id
            end

            def _get_single_relationship_by_dir(dir)
              iter = get_relationships(dir).iterator

              return nil if not iter.has_next

              first = iter.next
              fail ArgumentError, "Expected to only find one relationship from node #{neo_id} matching" if iter.has_next
              first
            end

            def _rels(match = {})
              dir, rel_type, between_id = _parse_match(match)

              args = rel_type ? [rel_type, dir] : [dir]
              rels = get_relationships(*args).iterator

              if between_id
                rels.find_all { |r| r.end_node.neo_id == between_id || r.start_node.neo_id == between_id }
              else
                rels
              end
            end

            def _parse_match(match)
              ::Neo4j::Node.validate_match!(match)

              [
                ToJava.dir_to_java(match[:dir] || :both),
                ToJava.type_to_java(match[:type]),
                match[:between] && match[:between].neo_id
              ]
            end

            include Neo4j::Node::Wrapper
          end
        end
      end
    end
  end
end
