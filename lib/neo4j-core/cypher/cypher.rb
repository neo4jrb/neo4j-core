module Neo4j
  module Core
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

        def neo_id
          Property.new(@expressions, self, 'ID').to_function!
        end

        def property?(p)
          p = Property.new(expressions, self, p)
          p.binary_operator("has")
        end

        def exist?
          p = Property.new(expressions, self, p)
          p.binary_operator("", " is null")
        end

        def is_a?(klass)
          return super if klass.class != Class || !klass.instance_methods.include?("wrapper")
          super
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
          i = @expressions.reverse.index { |e| e.clause == clause }
          if i.nil?
            @expressions << self
          else
            pos = @expressions.size - i
            @expressions.insert(pos, self)
          end
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

      class Property
        attr_reader :expressions, :var_name
        include Comparable
        include MathOperator
        include MathFunctions
        include PredicateMethods

        def initialize(expressions, var, prop_name)
          @var = var.respond_to?(:var_name) ? var.var_name : var
          @expressions = expressions
          @prop_name = prop_name
          @var_name = @prop_name ? "#{@var.to_s}.#{@prop_name}" : @var.to_s
        end

        def to_function!(var = @var.to_s)
          @var_name = "#{@prop_name}(#{var})"
          self
        end

        def as(new_name)
          @var_name = "#{@var_name} AS #{new_name}"
        end

        # required by the Predicate Methods Module
        # @see PredicateMethods
        def iterable
          var_name
        end

        def input
          self
        end

        def in?(values)
          binary_operator("", " IN [#{values.map { |x| %Q["#{x}"] }.join(',')}]")
        end

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

        def function(func_name_pre, func_name_post = "")
          ExprOp.new(self, nil, func_name_pre, func_name_post)
        end

        def binary_operator(op, post_fix = "")
          ExprOp.new(self, nil, op, post_fix).binary!
        end
      end

      class Start < Expression
        attr_reader :var_name
        include Variable
        include Matchable

        def initialize(var_name, expressions)
          @var_name = "#{var_name}#{expressions.size}"
          super(expressions, :start)
        end

      end

      class StartNode < Start
        attr_reader :nodes

        def initialize(nodes, expressions)
          super("n", expressions)

          @nodes = nodes.map { |n| n.respond_to?(:neo_id) ? n.neo_id : n }
        end

        def to_s
          "#{var_name}=node(#{nodes.join(',')})"
        end
      end

      class StartRel < Start
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

        def return_method
          @name_or_ref.respond_to?(:return_method) && @name_or_ref.return_method
        end

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

      class Skip < Expression
        def initialize(expressions, value)
          super(expressions, :skip)
          @value = value
        end

        def to_s
          @value
        end
      end

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

      class Match < Expression
        attr_reader :dir, :expressions, :left, :right, :var_name, :dir_op
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


        def nodes
          Entities.new(@expressions, "nodes", self)
        end

        def rels
          Entities.new(@expressions, "relationships", self)
        end

        def length
          self.return_method = {:name => 'length', :bracket => true}
          self
        end

        def find_match_start
          c = self
          while (c.prev) do
            c = c.prev
          end
          c
        end

        def left_var_name
          @left.respond_to?(:var_name) ? @left.var_name : @left.to_s
        end

        def right_var_name
          @right.respond_to?(:var_name) ? @right.var_name : @right.to_s
        end

        def right_expr
          @right.respond_to?(:expr) ? @right.expr : right_var_name
        end

        def referenced!
          @referenced = true
        end

        def referenced?
          !!@referenced
        end

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

        # @return [String] a cypher string for this match.
        def expr
          "#{dir_op}(#{right_var_name})"
        end

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
          guess = expr ? /([[:alpha:]]*)/.match(expr)[1] : ""
          @var_name = guess.empty? ? "v#{variables.size}" : guess
        end

        def rel_type
          Property.new(@expressions, self, 'type').to_function!
        end

        # @return [String] a cypher string for this relationship variable
        def to_s
          var_name
        end

      end

      class ExprOp < Expression
        attr_reader :left, :right, :op, :neg, :post_fix
        include MathFunctions

        def initialize(left, right, op, post_fix = "")
          super(left.expressions, :where)
          @op = op
          @post_fix = post_fix
          self.expressions.delete(left)
          self.expressions.delete(right)
          @left = quote(left)
          if regexp?(right)
            @op = "=~"
            @right = to_regexp(right)
          else
            @right = right && quote(right)
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
          #        puts "valid? @binary=#{@binary} (#@left #@op #@right) in clause #{clause} ret #{@binary ? !!@left : !!@left && !!@right}"
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
