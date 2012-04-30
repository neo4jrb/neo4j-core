module Neo4j
  module Core

    # This module contains a number of mixins and classes used by the neo4j.rb cypher DSL.
    # The Cypher DSL is evaluated in the context of {Neo4j::Cypher} which contains a number of methods (e.g. {Neo4j::Cypher#node})
    # which returns classes from this module.
    module Cypher

      module MathFunctions
        def abs(value=nil)
          _add_math_func(:abs, value)
        end

        def sqrt(value=nil)
          _add_math_func(:sqrt, value)
        end

        def round(value=nil)
          _add_math_func(:round, value)
        end

        def sign(value=nil)
          _add_math_func(:sign, value)
        end

        # @private
        def _add_math_func(name, value=nil)
          value ||= self.respond_to?(:var_name) ? self.var_name : to_s
          expressions.delete(self)
          Property.new(expressions, nil, name).to_function!(value)
        end
      end

      module MathOperator
        def -(other)
          ExprOp.new(self, other, '-')
        end

        def +(other)
          ExprOp.new(self, other, '+')
        end
      end

      module Comparable
        def <(other)
          ExprOp.new(self, other, '<')
        end

        def <=(other)
          ExprOp.new(self, other, '<=')
        end

        def =~(other)
          ExprOp.new(self, other, '=~')
        end

        def >(other)
          ExprOp.new(self, other, '>')
        end

        def >=(other)
          ExprOp.new(self, other, '>=')
        end

        ## Only in 1.9
        if RUBY_VERSION > "1.9.0"
          eval %{
            def !=(other)
              other.is_a?(String) ?  ExprOp.new(self, other, "!=") : super
            end  }
        end

        def ==(other)
          if other.is_a?(Fixnum) || other.is_a?(String) || other.is_a?(Regexp)
            ExprOp.new(self, other, "=")
          else
            super
          end
        end
      end

      module PredicateMethods
        def all?(&block)
          self.respond_to?(:iterable)
          Predicate.new(expressions, :op => 'all', :clause => :where, :input => input, :iterable => iterable, :predicate_block => block)
        end

        def extract(&block)
          Predicate.new(expressions, :op => 'extract', :clause => :return, :input => input, :iterable => iterable, :predicate_block => block)
        end

        def filter(&block)
          Predicate.new(expressions, :op => 'filter', :clause => :return, :input => input, :iterable => iterable, :predicate_block => block)
        end

        def any?(&block)
          Predicate.new(@expressions, :op => 'any', :clause => :where, :input => input, :iterable => iterable, :predicate_block => block)
        end

        def none?(&block)
          Predicate.new(@expressions, :op => 'none', :clause => :where, :input => input, :iterable => iterable, :predicate_block => block)
        end

        def single?(&block)
          Predicate.new(@expressions, :op => 'single', :clause => :where, :input => input, :iterable => iterable, :predicate_block => block)
        end

      end

      module Variable
        attr_accessor :return_method

        def distinct
          self.return_method = {:name => 'distinct', :bracket => false}
          self
        end

        def [](prop_name)
          Property.new(expressions, self, prop_name)
        end

        def as(v)
          @var_name = v
          self
        end

        # generates a <tt>ID</tt> cypher fragment.
        def neo_id
          Property.new(@expressions, self, 'ID').to_function!
        end

        # generates a <tt>has</tt> cypher fragment.
        def property?(p)
          p = Property.new(expressions, self, p)
          p.binary_operator("has")
        end

        # generates a <tt>is null</tt> cypher fragment.
        def exist?
          p = Property.new(expressions, self, p)
          p.binary_operator("", " is null")
        end

        # Can be used instead of [_classname] == klass
        def is_a?(klass)
          return super if klass.class != Class || !klass.respond_to?(:_load_wrapper)
          self[:_classname] == klass.to_s
        end
      end

      module Matchable
        # This operator means related to, without regard to type or direction.
        # @param [Symbol, #var_name] other either a node (Symbol, #var_name)
        # @return [MatchRelLeft, MatchNode]
        def <=>(other)
          MatchNode.new(self, other, expressions, :both)
        end

        # This operator means outgoing related to
        # @param [Symbol, #var_name, String] other the relationship
        # @return [MatchRelLeft, MatchNode]
        def >(other)
          MatchRelLeft.new(self, other, expressions, :outgoing)
        end

        # This operator means any direction related to
        # @param (see #>)
        # @return [MatchRelLeft, MatchNode]
        def -(other)
          MatchRelLeft.new(self, other, expressions, :both)
        end

        # This operator means incoming related to
        # @param (see #>)
        # @return [MatchRelLeft, MatchNode]
        def <(other)
          MatchRelLeft.new(self, other, expressions, :incoming)
        end

        # Outgoing relationship to other node
        # @param [Symbol, #var_name] other either a node (Symbol, #var_name)
        # @return [MatchRelLeft, MatchNode]
        def >>(other)
          MatchNode.new(self, other, expressions, :outgoing)
        end

        def outgoing(rel_type)
          node = NodeVar.new(@expressions, @variables)
          MatchRelLeft.new(self, ":`#{rel_type}`", expressions, :outgoing) > node
          node
        end

        def incoming(rel_type)
          node = NodeVar.new(@expressions, @variables)
          MatchRelLeft.new(self, ":`#{rel_type}`", expressions, :incoming) < node
          node
        end

        def both(rel_type)
          node = NodeVar.new(@expressions, @variables)
          MatchRelLeft.new(self, ":`#{rel_type}`", expressions, :both) < node
          node
        end

        # Incoming relationship to other node
        # @param [Symbol, #var_name] other either a node (Symbol, #var_name)
        # @return [MatchRelLeft, MatchNode]
        def <<(other)
          MatchNode.new(self, other, expressions, :incoming)
        end
      end

      class Expression
        attr_reader :expressions
        attr_accessor :separator, :clause

        def initialize(expressions, clause)
          @clause = clause
          @expressions = expressions
          insert_last(clause)
          @separator = ","
        end

        def insert_last(clause)
          curr_clause = clause
          while (i = @expressions.reverse.index { |e| e.clause == curr_clause }).nil? && curr_clause != :start
            curr_clause = prev_clause(curr_clause)
          end

          if i.nil?
            @expressions << self
          else
            pos = @expressions.size - i
            @expressions.insert(pos, self)
          end
        end

        def prev_clause(clause)
          {:limit => :skip, :skip => :order_by, :order_by => :return, :return => :where, :where => :match, :match => :start}[clause]
        end

        def prefixes
          {:start => "START", :where => " WHERE", :match => " MATCH", :return => " RETURN", :order_by => " ORDER BY", :skip => " SKIP", :limit => " LIMIT"}
        end

        def prefix
          prefixes[clause]
        end

        def valid?
          true
        end

      end

      # A property is returned from a Variable by using the [] operator.
      #
      # It has a number of useful method like
      # <tt>count</tt>, <tt>sum</tt>, <tt>avg</tt>, <tt>min</tt>, <tt>max</tt>, <tt>collect</tt>, <tt>head</tt>, <tt>last</tt>, <tt>tail</tt>,
      #
      # @example
      #  n=node(2, 3, 4); n[:name].collect
      #  # same as START n0=node(2,3,4) RETURN collect(n0.property)
      class Property
        # @private
        attr_reader :expressions, :var_name, :var_expr
        include Comparable
        include MathOperator
        include MathFunctions
        include PredicateMethods

        def initialize(expressions, var_expr, prop_name)
          @var_expr = var_expr
          @var = var_expr.respond_to?(:var_name) ? var_expr.var_name : var_expr
          @expressions = expressions
          @prop_name = prop_name
          @var_name = @prop_name ? "#{@var.to_s}.#{@prop_name}" : @var.to_s
        end

        # @private
        def to_function!(var = @var.to_s)
          @var_name = "#{@prop_name}(#{var})"
          self
        end

        # Make it possible to rename a property with a different name (AS)
        def as(new_name)
          @var_name = "#{@var_name} AS #{new_name}"
        end

        # required by the Predicate Methods Module
        # @see PredicateMethods
        # @private
        def iterable
          var_name
        end

        def input
          self
        end

        # @private
        def in?(values)
          binary_operator("", " IN [#{values.map { |x| %Q["#{x}"] }.join(',')}]")
        end

        # Only return distinct values/nodes/rels/paths
        def distinct
          @var_name = "distinct #{@var_name}"
          self
        end

        def length
          @prop_name = "length"
          to_function!
          self
        end

        %w[count sum avg min max collect head last tail].each do |meth_name|
          define_method(meth_name) do
            function(meth_name.to_s)
          end
        end

        # @private
        def function(func_name_pre, func_name_post = "")
          ExprOp.new(self, nil, func_name_pre, func_name_post)
        end

        # @private
        def binary_operator(op, post_fix = "")
          ExprOp.new(self, nil, op, post_fix).binary!
        end
      end

      class Start < Expression
        # @private
        attr_reader :var_name
        include Variable
        include Matchable

        def initialize(var_name, expressions)
          @var_name = "#{var_name}#{expressions.size}"
          super(expressions, :start)
        end

      end

      # Can be created from a <tt>node</tt> dsl method.
      class StartNode < Start
        # @private
        attr_reader :nodes

        def initialize(nodes, expressions)
          super("n", expressions)

          @nodes = nodes.map { |n| n.respond_to?(:neo_id) ? n.neo_id : n }
        end

        def to_s
          "#{var_name}=node(#{nodes.join(',')})"
        end
      end


      # Can be created from a <tt>rel</tt> dsl method.
      class StartRel < Start
        # @private
        attr_reader :rels

        def initialize(rels, expressions)
          super("r", expressions)
          @rels = rels.map { |n| n.respond_to?(:neo_id) ? n.neo_id : n }
        end

        def to_s
          "#{var_name}=relationship(#{rels.join(',')})"
        end
      end

      class NodeQuery < Start
        attr_reader :index_name, :query

        def initialize(index_class, query, index_type, expressions)
          super("n", expressions)
          @index_name = index_class.index_name_for_type(index_type)
          @query = query
        end

        def to_s
          "#{var_name}=node:#{index_name}(#{query})"
        end
      end

      class NodeLookup < Start
        attr_reader :index_name, :query

        def initialize(index_class, key, value, expressions)
          super("n", expressions)
          index_type = index_class.index_type(key.to_s)
          raise "No index on #{index_class} property #{key}" unless index_type
          @index_name = index_class.index_name_for_type(index_type)
          @query = %Q[#{key}="#{value}"]
        end

        def to_s
          %Q[#{var_name}=node:#{index_name}(#{query})]
        end

      end

      # The return statement in the cypher query
      class Return < Expression
        attr_reader :var_name

        def initialize(name_or_ref, expressions, opts = {})
          super(expressions, :return)
          @name_or_ref = name_or_ref
          @name_or_ref.referenced! if @name_or_ref.respond_to?(:referenced!)
          @var_name = @name_or_ref.respond_to?(:var_name) ? @name_or_ref.var_name : @name_or_ref.to_s
          opts.each_pair { |k, v| self.send(k, v) }
        end

        # @private
        def return_method
          @name_or_ref.respond_to?(:return_method) && @name_or_ref.return_method
        end

        # @private
        def as_return_method
          if return_method[:bracket]
            "#{return_method[:name]}(#@var_name)"
          else
            "#{return_method[:name]} #@var_name"
          end
        end

        # Specifies an <tt>ORDER BY</tt> cypher query
        # @param [Property] props the properties which should be sorted
        # @return self
        def asc(*props)
          @order_by ||= OrderBy.new(expressions)
          @order_by.asc(props)
          self
        end

        # Specifies an <tt>ORDER BY</tt> cypher query
        # @param [Property] props the properties which should be sorted
        # @return self
        def desc(*props)
          @order_by ||= OrderBy.new(expressions)
          @order_by.desc(props)
          self
        end

        # Creates a <tt>SKIP</tt> cypher clause
        # @param [Fixnum] val the number of entries to skip
        # @return self
        def skip(val)
          Skip.new(expressions, val)
          self
        end

        # Creates a <tt>LIMIT</tt> cypher clause
        # @param [Fixnum] val the number of entries to limit
        # @return self
        def limit(val)
          Limit.new(expressions, val)
          self
        end

        def to_s
          return_method ? as_return_method : var_name.to_s
        end
      end

      # Can be used to skip result from a return clause
      class Skip < Expression
        def initialize(expressions, value)
          super(expressions, :skip)
          @value = value
        end

        def to_s
          @value
        end
      end

      # Can be used to limit result from a return clause
      class Limit < Expression
        def initialize(expressions, value)
          super(expressions, :limit)
          @value = value
        end

        def to_s
          @value
        end
      end

      class OrderBy < Expression
        def initialize(expressions)
          super(expressions, :order_by)
          @orders = []
        end

        def asc(props)
          @orders << [:asc, props]
        end

        def desc(props)
          @orders << [:desc, props]
        end

        def to_s
          @orders.map do |pair|
            if pair[0] == :asc
              pair[1].map(&:var_name).join(', ')
            else
              pair[1].map(&:var_name).join(', ') + " DESC"
            end
          end.join(', ')
        end
      end

      # Created from a node's match operator like >> or <.
      class Match < Expression
        # @private
        attr_reader :dir, :expressions, :left, :right, :var_name, :dir_op
        # @private
        attr_accessor :algorithm, :next, :prev
        include Variable

        def initialize(left, right, expressions, dir, dir_op)
          super(expressions, :match)
          @var_name = "m#{expressions.size}"
          @dir = dir
          @dir_op = dir_op
          @prev = left if left.is_a?(Match)
          @left = left
          @right = right
        end


        # Generates a <tt>x in nodes(m3)</tt> cypher expression.
        #
        # @example
        #   p.nodes.all? { |x| x[:age] > 30 }
        def nodes
          Entities.new(@expressions, "nodes", self)
        end

        # Generates a <tt>x in relationships(m3)</tt> cypher expression.
        #
        # @example
        #   p.relationships.all? { |x| x[:age] > 30 }
        def rels
          Entities.new(@expressions, "relationships", self)
        end

        # returns the length of the path
        def length
          self.return_method = {:name => 'length', :bracket => true}
          self
        end

        # @private
        def find_match_start
          c = self
          while (c.prev) do
            c = c.prev
          end
          c
        end

        # @private
        def left_var_name
          @left.respond_to?(:var_name) ? @left.var_name : @left.to_s
        end

        # @private
        def right_var_name
          @right.respond_to?(:var_name) ? @right.var_name : @right.to_s
        end

        # @private
        def right_expr
          c = @right
          r = while (c)
                break c.var_expr if c.respond_to?(:var_expr)
                c = c.respond_to?(:left_expr) && c.left_expr
              end || @right

          r.respond_to?(:expr) ? r.expr : right_var_name
        end

        # @private
        def referenced!
          @referenced = true
        end

        # @private
        def referenced?
          !!@referenced
        end

        # @private
        def to_s
          curr = find_match_start
          result = (referenced? || curr.referenced?) ? "#{var_name} = " : ""
          result << (algorithm ? "#{algorithm}(" : "")
          begin
            result << curr.expr
          end while (curr = curr.next)
          result << ")" if algorithm
          result
        end
      end

      # The left part of a match clause, e.g. node < rel(':friends')
      # Can return {MatchRelRight} using a match operator method.
      class MatchRelLeft < Match
        def initialize(left, right, expressions, dir)
          super(left, right, expressions, dir, dir == :incoming ? '<-' : '-')
        end

        # @param [Symbol,NodeVar,String] other part of the match cypher statement.
        # @return [MatchRelRight] the right part of an relationship cypher query.
        def >(other)
          expressions.delete(self)
          self.next = MatchRelRight.new(self, other, expressions, :outgoing)
        end

        # @see #>
        # @return (see #>)
        def <(other)
          expressions.delete(self)
          self.next = MatchRelRight.new(self, other, expressions, :incoming)
        end

        # @see #>
        # @return (see #>)
        def -(other)
          expressions.delete(self)
          self.next = MatchRelRight.new(self, other, expressions, :both)
        end

        # @return [String] a cypher string for this match.
        def expr
          if prev
            # we have chained more then one relationships in a match expression
            "#{dir_op}[#{right_expr}]"
          else
            # the right is an relationship and could be an expressions, e.g "r?"
            "(#{left_var_name})#{dir_op}[#{right_expr}]"
          end
        end
      end

      class MatchRelRight < Match
        # @param left the left part of the query
        # @param [Symbol,NodeVar,String] right part of the match cypher statement.
        def initialize(left, right, expressions, dir)
          super(left, right, expressions, dir, dir == :outgoing ? '->' : '-')
        end

        # @param [Symbol,NodeVar,String] other part of the match cypher statement.
        # @return [MatchRelLeft] the right part of an relationship cypher query.
        def >(other)
          expressions.delete(self)
          self.next = MatchRelLeft.new(self, other, expressions, :outgoing)
        end

        # @see #>
        # @return (see #>)
        def <(other)
          expressions.delete(self)
          self.next = MatchRelLeft.new(self, other, expressions, :incoming)
        end

        # @see #>
        # @return (see #>)
        def -(other)
          expressions.delete(self)
          self.next = MatchRelLeft.new(self, other, expressions, :both)
        end

        def <<(other)
          expressions.delete(self)
          self.next = MatchNode.new(self, other, expressions, :incoming)
        end

        def >>(other)
          expressions.delete(self)
          self.next = MatchNode.new(self, other, expressions, :outgoing)
        end

        # @return [String] a cypher string for this match.
        def expr
          "#{dir_op}(#{right_var_name})"
        end

        # negate this match
        def not
          expressions.delete(self)
          ExprOp.new(left, nil, "not").binary!
        end

        if RUBY_VERSION > "1.9.0"
          eval %{
             def !
          expressions.delete(self)
          ExprOp.new(left, nil, "not").binary!
             end
             }
        end

      end

      # The right part of a match clause (node_b), e.g. node_a > rel(':friends') > node_b
      #
      class MatchNode < Match
        attr_reader :dir_op

        def initialize(left, right, expressions, dir)
          dir_op = case dir
                     when :outgoing then
                       "-->"
                     when :incoming then
                       "<--"
                     when :both then
                       "--"
                   end
          super(left, right, expressions, dir, dir_op)
        end

        # @return [String] a cypher string for this match.
        def expr
          if prev
            # we have chained more then one relationships in a match expression
            "#{dir_op}(#{right_expr})"
          else
            # the right is an relationship and could be an expressions, e.g "r?"
            "(#{left_var_name})#{dir_op}(#{right_expr})"
          end
        end

        def <<(other)
          expressions.delete(self)
          self.next = MatchNode.new(self, other, expressions, :incoming)
        end

        def >>(other)
          expressions.delete(self)
          self.next = MatchNode.new(self, other, expressions, :outgoing)
        end

        # @param [Symbol,NodeVar,String] other part of the match cypher statement.
        # @return [MatchRelRight] the right part of an relationship cypher query.
        def >(other)
          expressions.delete(self)
          self.next = MatchRelLeft.new(self, other, expressions, :outgoing)
        end

        # @see #>
        # @return (see #>)
        def <(other)
          expressions.delete(self)
          self.next = MatchRelLeft.new(self, other, expressions, :incoming)
        end

        # @see #>
        # @return (see #>)
        def -(other)
          expressions.delete(self)
          self.next = MatchRelLeft.new(self, other, expressions, :both)
        end

      end

      # Represents an unbound node variable used in match statements
      class NodeVar
        include Variable
        include Matchable

        # @return the name of the variable
        attr_reader :var_name
        attr_reader :expressions

        def initialize(expressions, variables)
          variables ||= []
          @var_name = "v#{variables.size}"
          variables << self
          @variables = variables
          @expressions = expressions
        end

        # @return [String] a cypher string for this node variable
        def to_s
          var_name
        end

      end

      # represent an unbound relationship variable used in match,where,return statement
      class RelVar
        include Variable

        attr_reader :var_name, :expr, :expressions

        def initialize(expressions, variables, expr)
          variables << self
          @expr = expr
          @expressions = expressions
          guess = expr ? /([[:alpha:]_]*)/.match(expr)[1] : ""
          @auto_var_name = "v#{variables.size}"
          @var_name = guess.empty? ? @auto_var_name : guess
        end

        def rel_type
          Property.new(@expressions, self, 'type').to_function!
        end

        def [](p)
          if @expr.to_s[0..0] == ':'
            @var_name = @auto_var_name
            @expr = "#{@var_name}#{@expr}"
          end
          super
        end

        # @return [String] a cypher string for this relationship variable
        def to_s
          var_name
        end

      end

      class ExprOp < Expression
        attr_reader :left, :right, :op, :neg, :post_fix, :left_expr, :right_expr
        include MathFunctions


        def initialize(left_expr, right_expr, op, post_fix = "")
          super(left_expr.expressions, :where)
          @left_expr = left_expr
          @right_expr = right_expr
          @op = op
          @post_fix = post_fix
          self.expressions.delete(left_expr)
          self.expressions.delete(right_expr)
          @left = quote(left_expr)
          if regexp?(right_expr)
            @op = "=~"
            @right = to_regexp(right_expr)
          else
            @right = right_expr && quote(right_expr)
          end
          @neg = nil
        end

        def separator
          " "
        end

        def quote(val)
          if val.respond_to?(:var_name) && !val.kind_of?(Match)
            val.var_name
          else
            val.is_a?(String) ? %Q["#{val}"] : val
          end
        end

        def regexp?(right)
          @op == "=~" || right.is_a?(Regexp)
        end

        def to_regexp(val)
          %Q[/#{val.respond_to?(:source) ? val.source : val.to_s}/]
        end

        def count
          ExprOp.new(self, nil, 'count')
        end

        def &(other)
          ExprOp.new(self, other, "and")
        end

        def |(other)
          ExprOp.new(self, other, "or")
        end

        def -@
          @neg = "not"
          self
        end

        def not
          @neg = "not"
          self
        end

        # Only in 1.9
        if RUBY_VERSION > "1.9.0"
          eval %{
             def !
               @neg = "not"
               self
             end
             }
        end

        def left_to_s
          left.is_a?(ExprOp) ? "(#{left})" : left
        end

        def right_to_s
          right.is_a?(ExprOp) ? "(#{right})" : right
        end

        def binary!
          @binary = true
          self
        end

        def valid?
          # it is only valid in a where clause if it's either binary or it has right and left values
          @binary ? @left : @left && @right
        end

        def to_s
          if @right
            neg ? "#{neg}(#{left_to_s} #{op} #{right_to_s})" : "#{left_to_s} #{op} #{right_to_s}"
          else
            # binary operator
            neg ? "#{neg}#{op}(#{left_to_s}#{post_fix})" : "#{op}(#{left_to_s}#{post_fix})"
          end
        end
      end

      class Where < Expression
        def initialize(expressions, where_statement = nil)
          super(expressions, :where)
          @where_statement = where_statement
        end

        def to_s
          @where_statement.to_s
        end
      end

      class Predicate < Expression
        attr_accessor :params

        def initialize(expressions, params)
          @params = params
          @identifier = :x
          params[:input].referenced! if params[:input].respond_to?(:referenced!)
          super(expressions, params[:clause])
        end

        def identifier(i)
          @identifier = i
          self
        end

        def to_s
          input = params[:input]
          if input.kind_of?(Property)
            yield_param = Property.new([], @identifier, nil)
            args = ""
          else
            yield_param = NodeVar.new([], []).as(@identifier.to_sym)
            args = "(#{input.var_name})"
          end
          context = Neo4j::Cypher.new(yield_param, &params[:predicate_block])
          context.expressions.each { |e| e.clause = nil }
          if params[:clause] == :return
            where_or_colon = ':'
          else
            where_or_colon = 'WHERE'
          end
          predicate_value = context.to_s[1..-1] # skip separator ,
          "#{params[:op]}(#@identifier in #{params[:iterable]}#{args} #{where_or_colon} #{predicate_value})"
        end
      end

      class Entities
        include PredicateMethods
        attr_reader :input, :expressions, :iterable

        def initialize(expressions, iterable, input)
          @iterable = iterable
          @input = input
          @expressions = expressions
        end

      end

    end

  end

end
