module Neo4j
  module Core
    module Traversal

      class CypherQuery
        include Enumerable
        attr_accessor :query, :return_variable

        def initialize(start_id, dir, types, query_hash=nil, &block)
          this = self

          rel_type = ":#{types.map{|x| "`#{x}`"}.join('|')}"

          @query = Neo4j::Cypher.new do
            default_ret = node(:default_ret)
            n = node(start_id)
            case dir
              when :outgoing then
                n > rel_type > default_ret
              when :incoming then
                n < rel_type < default_ret
              when :both then
                n - rel_type - default_ret
            end

            # where statement
            ret_maybe = block && self.instance_exec(default_ret, &block)
            ret = ret_maybe.respond_to?(:var_name) ? ret_maybe : default_ret
            if query_hash
              expr = []
              query_hash.each{|pair|  expr << (ret[pair[0]] == pair[1])}.to_a
              expr.each_with_index do |obj, i|
                Neo4j::Core::Cypher::ExprOp.new(obj, expr[i+1], "and") if i < expr.size - 1
              end
            end

            this.return_variable = ret.var_name.to_sym
            ret
          end.to_s
        end

        def to_s
          @query
        end

        def each
          Neo4j._query(query).each do |r|
            yield r[return_variable]
          end
        end
      end

      # By using this class you can both specify traversals and create new relationships.
      # This object is return from the Neo4j::Core::Traversal methods.
      # @see Neo4j::Core::Traversal#outgoing
      # @see Neo4j::Core::Traversal#incoming
      class Traverser
        include Enumerable
        include ToJava


        def initialize(from, dir=:both, type=nil)
          @from = from
          @depth = 1
          if type.nil?
            raise "Traversing all relationship in direction #{dir.inspect} not supported, only :both supported" unless dir == :both
            @td = Java::OrgNeo4jKernelImplTraversal::TraversalDescriptionImpl.new.breadth_first()
          elsif (dir == :both)
            both(type)
          elsif (dir == :incoming)
            incoming(type)
          elsif (dir == :outgoing)
            outgoing(type)
          else
            raise "Illegal direction #{dir.inspect}, expected :outgoing, :incoming or :both"
          end
        end


        def query(query_hash = nil, &block)
          # only one direction is supported
          rel_types = [@outgoing_rel_types, @incoming_rel_types, @both_rel_types].find_all { |x| !x.nil? }
          raise "Only one direction is allowed, outgoing:#{@outgoing_rel_types}, incoming:#{@incoming_rel_types}, @both:#{@both_rel_types}" if rel_types.count != 1
          start_id = @from.neo_id
          dir = (@outgoing_rel_types && :outgoing) || (@incoming_rel_types && :incoming) || (@both_rel_types && :both)
          CypherQuery.new(start_id, dir, rel_types.first, query_hash, &block)
        end

        # Sets traversing depth first.
        #
        # The <tt>pre_or_post</tt> parameter parameter can have two values: :pre or :post
        # @param [:pre, :post] pre_or_post
        # * :pre - Traversing depth first, visiting each node before visiting its child nodes (default)
        # * :post - Traversing depth first, visiting each node after visiting its child nodes.
        # @return self
        #
        def depth_first(pre_or_post = :pre)
          case pre_or_post
            when :pre then
              @td = @td.order(Java::OrgNeo4jKernel::Traversal.preorderDepthFirst())
            when :post then
              @td = @td.order(Java::OrgNeo4jKernel::Traversal.postorderDepthFirst())
            else
              raise "Unknown type #{pre_or_post}, should be :pre or :post"
          end
          self
        end


        # Sets traversing breadth first (default).
        #
        # This is the default ordering if none is defined.
        # The <tt>pre_or_post</tt> parameter parameter can have two values: <tt>:pre</tt> or <tt>:post</tt>
        # * :pre - Traversing breadth first, visiting each node before visiting its child nodes (default)
        # * :post - Traversing breadth first, visiting each node after visiting its child nodes.
        #
        # @param [:pre, :post] pre_or_post The traversal order
        # @return self
        #
        # === Note
        # Please note that breadth first traversals have a higher memory overhead than depth first traversals.
        # BranchSelectors carries state and hence needs to be uniquely instantiated for each traversal.
        # Therefore it is supplied to the TraversalDescription through a BranchOrderingPolicy interface, which is a factory of BranchSelector instances.
        def breadth_first(pre_or_post = :pre)
          case pre_or_post
            when :pre then
              @td = @td.order(Java::OrgNeo4jKernel::Traversal.preorderBreadthFirst())
            when :post then
              @td = @td.order(Java::OrgNeo4jKernel::Traversal.postorderBreadthFirst())
            else
              raise "Unknown type #{pre_or_post}, should be :pre or :post"
          end
          self
        end


        def eval_paths(&eval_path_block)
          @td = @td.evaluator(Evaluator.new(&eval_path_block))
          self
        end

        # Sets the rules for how positions can be revisited during a traversal as stated in Uniqueness.
        # @param [:node_global, :node_path, :node_recent, :none, :rel_global, :rel_path, :rel_recent] u the uniqueness option
        # @return self
        # @see Neo4j::Core::Traverser#unique
        def unique(u = :node_global)
          case u
            when :node_global then
              # A node cannot be traversed more than once.
              @td = @td.uniqueness(Java::OrgNeo4jKernel::Uniqueness::NODE_GLOBAL)
            when :node_path then
              # For each returned node there 's a unique path from the start node to it.
              @td = @td.uniqueness(Java::OrgNeo4jKernel::Uniqueness::NODE_PATH)
            when :node_recent then
              # This is like NODE_GLOBAL, but only guarantees uniqueness among the most recent visited nodes, with a configurable count.
              @td = @td.uniqueness(Java::OrgNeo4jKernel::Uniqueness::NODE_RECENT)
            when :none then
              # No restriction (the user will have to manage it).
              @td = @td.uniqueness(Java::OrgNeo4jKernel::Uniqueness::NONE)
            when :rel_global then
              # A relationship cannot be traversed more than once, whereas nodes can.
              @td = @td.uniqueness(Java::OrgNeo4jKernel::Uniqueness::RELATIONSHIP_GLOBAL)
            when :rel_path then
              # No restriction (the user will have to manage it).
              @td = @td.uniqueness(Java::OrgNeo4jKernel::Uniqueness::RELATIONSHIP_PATH)
            when :rel_recent then
              # Same as for NODE_RECENT, but for relationships.
              @td = @td.uniqueness(Java::OrgNeo4jKernel::Uniqueness::RELATIONSHIP_RECENT)
            else
              raise "Got option for unique '#{u}' allowed: :node_global, :node_path, :node_recent, :none, :rel_global, :rel_path, :rel_recent"
          end
          self
        end

        def to_s
          "NodeTraverser [from: #{@from.neo_id} depth: #{@depth}"
        end


        # Creates a new relationship between given node and self
        # It can create more then one relationship
        #
        # @example One outgoing relationships
        #   node.outgoing(:foo) << other_node
        #
        # @example Two outgoing relationships
        #   node.outgoing(:foo).outgoing(:bar) << other_node
        #
        # @param [Neo4j::Node] other_node the node to which we want to create a relationship
        # @return (see #new)
        def <<(other_node)
          new(other_node)
          self
        end

        # Returns an real ruby array.
        def to_ary
          self.to_a
        end

        # Creates a new relationship between self and given node.
        # It can create more then one relationship
        # This method is used by the <tt><<</tt> operator.
        #
        # @example create one relationship
        #   node.outgoing(:bar).new(other_node, rel_props)
        #
        # @example two relationships
        #   node.outgoing(:bar).outgoing(:foo).new(other_node, rel_props)
        #
        # @example both incoming and outgoing - two relationships
        #   node.both(:bar).new(other_node, rel_props)
        #
        # @see #<<
        # @param [Hash] props properties of new relationship
        # @return [Neo4j::Relationship] the created relationship
        def new(other_node, props = {})
          @outgoing_rel_types && @outgoing_rel_types.each { |type| _new_out(other_node, type, props) }
          @incoming_rel_types && @incoming_rel_types.each { |type| _new_in(other_node, type, props) }
          @both_rel_types && @both_rel_types.each { |type| _new_both(other_node, type, props) }
        end

        # @private
        def _new_out(other_node, type, props)
          @from.create_relationship_to(other_node, type_to_java(type)).update(props)
        end

        # @private
        def _new_in(other_node, type, props)
          other_node.create_relationship_to(@from, type_to_java(type)).update(props)
        end

        # @private
        def _new_both(other_node, type, props)
          _new_out(other_node, type, props)
          _new_in(other_node, type, props)
        end

        # @param (see Neo4j::Core::Traversal#both)
        # @see Neo4j::Core::Traversal#both
        def both(type)
          @both_rel_types ||= []
          @both_rel_types << type
          _add_rel(:both, type)
          self
        end

        # @param (see Neo4j::Core::Traversal#expand)
        # @return self
        # @see Neo4j::Core::Traversal#expand
        def expander(&expander)
          @td = @td.expand(RelExpander.create_pair(&expander))
          self
        end

        # Adds one outgoing relationship type to the traversal
        # @param (see Neo4j::Core::Traversal#outgoing)
        # @return self
        # @see Neo4j::Core::Traversal#outgoing
        def outgoing(type)
          @outgoing_rel_types ||= []
          @outgoing_rel_types << type
          _add_rel(:outgoing, type)
          self
        end

        # Adds one incoming relationship type to the traversal
        # @param (see Neo4j::Core::Traversal#incoming)
        # @return self
        # @see Neo4j::Core::Traversal#incoming
        def incoming(type)
          @incoming_rel_types ||= []
          @incoming_rel_types << type
          _add_rel(:incoming, type)
          self
        end

        # @private
        def _add_rel(dir, type)
          t = type_to_java(type)
          d = dir_to_java(dir)
          @td = @td ? @td.relationships(t, d) : Java::OrgNeo4jKernelImplTraversal::TraversalDescriptionImpl.new.breadth_first().relationships(t, d)
        end

        # Cuts of of parts of the traversal.
        # @yield [path]
        # @yieldparam [Java::OrgNeo4jGraphdb::Path] path the path which can be used to filter nodes
        # @yieldreturn [true,false] only if true the path should be cut of, no traversal beyond this.
        # @example
        #  a.outgoing(:friends).outgoing(:recommend).depth(:all).prune{|path| path.end_node[:name] == 'B'}
        # @see http://components.neo4j.org/neo4j/milestone/apidocs/org/neo4j/graphdb/Path.html
        def prune(&block)
          @td = @td.prune(PruneEvaluator.new(block))
          self
        end

        # Only include nodes in the traversal in which the provided block returns true.
        # @yield [path]
        # @yieldparam [Java::OrgNeo4jGraphdb::Path] path the path which can be used to filter nodes
        # @yieldreturn [true,false] only if true the node will be included in the traversal result.
        #
        # @example Return nodes that are exact at depth 2 from me
        #   a_node.outgoing(:friends).depth(2).filter{|path| path.length == 2}
        # @see http://components.neo4j.org/neo4j/milestone/apidocs/org/neo4j/graphdb/Path.html
        def filter(&block)
          # we keep a reference to filter predicate since only one filter is allowed and we might want to modify it
          @filter_predicate ||= FilterPredicate.new
          @filter_predicate.add(block)


          @td = @td.filter(@filter_predicate)
          self
        end

        # Sets depth, if :all then it will traverse any depth
        # @param [Fixnum, :all] d the depth of traversal, or all
        # @return self
        def depth(d)
          @depth = d
          self
        end

        # By default the start node is not included in the traversal
        # Specifies that the start node should be included
        # @return self
        def include_start_node
          @include_start_node = true
          self
        end

        # @param [Fixnum] index the n'th node that will be return from the traversal
        def [](index)
          each_with_index { |node, i| break node if index == i }
        end

        # @return [true,false]
        def empty?
          first == nil
        end

        # Required by the Ruby Enumerable Mixin
        def each
          @raw ? iterator.each { |i| yield i } : iterator.each { |i| yield i.wrapper }
        end

        # Same as #each but does not wrap each node in a Ruby class, yields the Java Neo4j Node instance instead.
        def each_raw
          iterator.each { |i| yield i }
        end

        # Returns an enumerable of relationships instead of nodes
        # @return self
        def rels
          @traversal_result = :rels
          self
        end

        # If this is called then it will not wrap the nodes but instead return the raw Java Neo4j::Node objects when traversing
        # @return self
        def raw
          @raw = true
          self
        end

        # Specifies that we should return an enumerable of paths instead of nodes.
        # @return self
        def paths
          @traversal_result = :paths
          @raw = true
          self
        end

        # @return the java iterator
        def iterator
          unless @include_start_node
            if @filter_predicate
              @filter_predicate.include_start_node
            else
              @td = @td.evaluator(Java::OrgNeo4jGraphdbTraversal::Evaluators.exclude_start_position)
            end
          end
          @td = @td.evaluator(Java::OrgNeo4jGraphdbTraversal::Evaluators.toDepth(@depth)) unless @depth == :all
          if @traversal_result == :rels
            @td.traverse(@from._java_node).relationships
          elsif @traversal_result == :paths
            @td.traverse(@from._java_node).iterator
          else
            @td.traverse(@from._java_node).nodes
          end

        end

      end
    end
  end
end