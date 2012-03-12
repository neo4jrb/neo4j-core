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

      # This operator means related to, without regard to type or direction.
      # @param [Array, Symbol, #var_name] other either a node (Symbol, #var_name) or a relationship (Array)
      # @return [MatchRelLeft, MatchNode]
      def <=>(other)
        other.is_a?(Array) ? MatchRelLeft.new(self, other, expressions, :both) : MatchNode.new(self, other, expressions, :both)
      end

      # Outgoing relationship
      # @param [Array, Symbol, #var_name] other either a node (Symbol, #var_name) or a relationship (Array)
      # @return [MatchRelLeft, MatchNode]
      def >>(other)
        !other.is_a?(Symbol) ? MatchRelLeft.new(self, other, expressions, :outgoing) : MatchNode.new(self, other, expressions, :outgoing)
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
      attr_reader :left, :right, :dir, :expressions

      def initialize(left, right, expressions, dir)
        super(expressions)
        @dir = dir
        @left = left
        @right = right
      end

      def prefix
        " MATCH"
      end

      def var_name_for(v)
        return v.var_name if v.respond_to?(:var_name)
        return ":#{v}" if v.is_a?(String)
        v.to_s
      end

    end

    class MatchRelLeft < Match
      def initialize(left, right, expressions, dir)
        super(left, right.respond_to?(:first) ? right.first: right, expressions, dir)
      end

      def >>(other)
        MatchRelRight.new(self, other, expressions, dir)
      end

      def to_s
        "(#{var_name_for(left)})-[#{var_name_for(right)}]"
      end
    end

    class MatchRelRight < Match
      attr_reader :dir_op

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

      def to_s
        "#{dir_op}(#{var_name_for(right)})"
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

      def to_s
        "(#{left.var_name})#{dir_op}(#{right})"
      end
    end

    def initialize(query = nil, &dsl_block)
      @expressions = []
      res = if query
              self.instance_eval(query)
            else
              self.instance_eval(&dsl_block)
            end
      unless res.kind_of?(Return)
        res.respond_to?(:to_a) ? ret(*res) : ret(res)
      end
    end


    # Does nothing, just for making the DSL less cryptic
    # @return self
    def match(*)
      self
    end

    # Does nothing, just for making the DSL less cryptic
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

    # @param [Fixnum] nodes the id of the nodes we want to start from
    # @return [StartNode]
    def node(*nodes)
      StartNode.new(nodes, @expressions)
    end

    # @return [StartRel]
    def rel(*rels)
      StartRel.new(rels, @expressions)
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