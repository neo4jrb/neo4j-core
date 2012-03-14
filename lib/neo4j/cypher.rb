module Neo4j
  class Cypher
    class Expression
      attr_reader :expressions
      attr_accessor :separator

      def initialize(expressions)
        @expressions = expressions
        @expressions << self
        @separator = ","
      end

    end

    class Start < Expression
      attr_reader :var_name

      def initialize(var_name, expressions)
        @var_name = "#{var_name}#{expressions.size}"
        super(expressions)
      end

      def as(v)
        @var_name = v
        self
      end

      # This operator means related to, without regard to type or direction.
      # @param [Array, Symbol, #var_name] other either a node (Symbol, #var_name) or a relationship (Array)
      # @return [MatchRelLeft, MatchNode]
      def <=>(other)
        MatchNode.new(self, other, expressions, :both)
      end

      # This operator means related to, without regard to type or direction.
      # @param [Array, Symbol, #var_name] other either a node (Symbol, #var_name) or a relationship (Array)
      # @return [MatchRelLeft, MatchNode]
      def >(other)
        MatchRelLeft.new(self, other, expressions, :outgoing)
      end

      # Outgoing relationship
      # @param [Array, Symbol, #var_name] other either a node (Symbol, #var_name) or a relationship (Array)
      # @return [MatchRelLeft, MatchNode]
      def >>(other)
        MatchNode.new(self, other, expressions, :outgoing)
      end

      def prefix
        "START"
      end
    end

    class StartNode < Start
      attr_reader :nodes

      def initialize(nodes, expressions)
        super("n", expressions)
        @nodes = nodes
      end

      def to_s
        "#{var_name}=node(#{nodes.join(',')})"
      end
    end

    class StartRel < Start
      attr_reader :rels

      def initialize(rels, expressions)
        super("r", expressions)
        @rels = rels
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
      def initialize(name_or_ref, expressions)
        super(expressions)
        @name_or_ref = name_or_ref
      end

      def prefix
        " RETURN"
      end

      def to_s
        @name_or_ref.is_a?(Symbol) ? @name_or_ref.to_s : @name_or_ref.var_name
      end
    end


    class Match < Expression
      attr_reader :dir, :expressions

      def initialize(left, right, expressions, dir)
        super(expressions)
        @dir = dir
        @left = left
        @right = right
      end

      def prefix
        " MATCH"
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
    end

    class MatchRelLeft < Match
      def initialize(left, right, expressions, dir)
        super(left, right, expressions, dir)
      end

      # @param [Symbol,NodeVar,String] other part of the match cypher statement.
      # @return [MatchRelRight] the right part of an relationship cypher query.
      def >(other)
        MatchRelRight.new(self, other, expressions, dir)
      end

      # @return [String] a cypher string for this match.
      def to_s
        "(#{left_var_name})-[#{right_expr}]"
      end
    end

    class MatchRelRight < Match
      attr_reader :dir_op

      # @param left the left part of the query
      # @param [Symbol,NodeVar,String] right part of the match cypher statement.
      def initialize(left, right, expressions, dir)
        super(left, right, expressions, dir)
        self.separator = ""
        @dir_op = case dir
                    when :outgoing then
                      "->"
                    when :incoming then
                      "<-"
                    when :both then
                      "-"
                  end
      end

      # @return [String] a cypher string for this match.
      def to_s
        "#{dir_op}(#{right_var_name})"
      end
    end

    class MatchNode < Match
      attr_reader :dir_op

      def initialize(left, right, expressions, dir)
        super(left, right, expressions, dir)
        @dir_op = case dir
                    when :outgoing then
                      "-->"
                    when :incoming then
                      "<--"
                    when :both then
                      "--"
                  end
      end

      # @return [String] a cypher string for this match.
      def to_s
        "(#{left_var_name})#{dir_op}(#{right_var_name})"
      end
    end

    # Represents an unbound node variable used in match statements
    class NodeVar
      # @return the name of the variable
      attr_reader :var_name

      def initialize(variables)
        @var_name = "v#{variables.size}"
        variables << self
      end

      # @return [String] a cypher string for this node variable
      def to_s
        var_name
      end

      # If this method is not used then it will automatically generate a variable name (#var_name)
      # @param [Symbol] v the name of this variable
      # @return self
      # @see #var_name
      def as(v)
        @var_name = v
        self
      end
    end


    # represent an unbound relationship variable used in match,where,return statement
    class RelVar
      attr_reader :var_name, :expr

      def initialize(expr, variables)
        variables << self
        @expr = expr
        guess = expr ? /([[:alpha:]]*)/.match(expr)[1] : ""
        @var_name = guess.empty? ? "v#{variables.size}" : guess
      end

      # @return [String] a cypher string for this relationship variable
      def to_s
        var_name
      end

      # If this method is not used then it will automatically generate a variable name (#var_name)
      # @param [Symbol] v the name of this variable
      # @return self
      # @see #var_name
      def as(v)
        @var_name = v
        self
      end
    end


    # Creates a Cypher DSL query.
    # To create a new cypher query you must initialize it either an String or a Block.
    #
    # @example <tt>START n0=node(3) MATCH (n0)--(x) RETURN x</tt>`same as
    #   Cypher.new { start n = node(3); match n <=> :x; ret :x }.to_s
    #
    # @example <tt>START n0=node(3) MATCH (n0)-[r]->(x) RETURN r</tt> same as
    #   node(3) > :r > :x; :r
    #
    # @example <tt>START n0=node(3) MATCH (n0)-->(x) RETURN x</tt> same as
    #   node(3) >> :x; :x
    #
    # @param [String] query the query expressed as an string instead of an block/yield.
    # @yield the block which will be evaluated in the context of this object in order to create an Cypher Query string
    # @yieldreturn [Return, Object] If the return is not an instance of Return it will be converted it to a Return object (if possible).
    def initialize(query = nil, &dsl_block)
      @expressions = []
      @variables = []
      res = if query
              self.instance_eval(query)
            else
              self.instance_eval(&dsl_block)
            end
      unless res.kind_of?(Return)
        res.respond_to?(:to_a) ? ret(*res) : ret(res)
      end
    end


    # Does nothing, just for making the DSL easier to read (maybe).
    # @return self
    def match(*)
      self
    end

    # Does nothing, just for making the DSL easier to read (maybe)
    # @return self
    def start(*)
      self
    end

    # Specifies a start node by performing a lucene query.
    # @param [Class] index_class a class responsible for an index
    # @param [String] q the lucene query
    # @param [Symbol] index_type the type of index
    # @return [NodeQuery]
    def query(index_class, q, index_type = :exact)
      NodeQuery.new(index_class, q, index_type, @expressions)
    end

    # Specifies a start node by performing a lucene query.
    # @param [Class] index_class a class responsible for an index
    # @param [String, Symbol] key the key we ask for
    # @param [String, Symbol] value the value of the key we ask for
    # @return [NodeLookup]
    def lookup(index_class, key, value)
      NodeLookup.new(index_class, key, value, @expressions)
    end

    # Creates a node variable.
    # It will create different variables depending on the type of the first element in the nodes argument.
    # * Fixnum - it will be be used as neo_id  for start node(s) (StartNode)
    # * Symbol - it will create an unbound node variable with the same name as the symbol (NodeVar#as)
    # * empty array - it will create an unbound node variable (NodeVar)
    #
    # @param [Fixnum,Symbol,String] nodes the id of the nodes we want to start from
    # @return [StartNode, NodeVar]
    def node(*nodes)
      if nodes.first.is_a?(Symbol)
        NodeVar.new(@variables).as(nodes.first)
      elsif !nodes.empty?
        StartNode.new(nodes, @expressions)
      else
        NodeVar.new(@variables)
      end
    end

    # Similar to #node
    # @return [StartRel, RelVar]
    def rel(*rels)
      if rels.first.is_a?(Fixnum)
        StartRel.new(rels, @expressions)
      elsif rels.first.is_a?(Symbol)
        RelVar.new("", @variables).as(rels.first)
      elsif rels.first.is_a?(String)
        RelVar.new(rels.first, @variables)
      else
        raise "Unknown arg #{rels.inspect}"
      end
    end

    # Specifies a return statement.
    # Notice that this is not needed, since the last value of the DSL block will be converted into one or more
    # return statements.
    # @param [Symbol, #var_name] returns a list of variables we want to return
    # @return [Return]
    def ret(*returns)
      returns.each { |ret| Return.new(ret, @expressions) }
      @expressions.last
    end

    # Converts the DSL query to a cypher String which can be executed by cypher query engine.
    def to_s
      curr_prefix = nil
      @expressions.map do |expr|
        expr_to_s = expr.prefix != curr_prefix ? "#{expr.prefix} #{expr.to_s}" : "#{expr.separator}#{expr.to_s}"
        curr_prefix = expr.prefix
        expr_to_s
      end.join
    end
  end
end