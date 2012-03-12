module Neo4j
  class Cypher
    class Start
      attr_reader :var_name, :expressions

      def initialize(var_name, expressions)
        @var_name = "#{var_name}#{expressions.size}"
        @expressions = expressions
        @expressions << self
      end

      def <=>(other)
        other.is_a?(Array) ? MatchRelLeft.new(self, other, expressions, :both) : Match.new(self, other, expressions, :both)
      end

      def >>(other)
        other.is_a?(Array) ? MatchRelLeft.new(self, other, expressions, :outgoing) : Match.new(self, other, expressions, :outgoing)
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

    class Return
      def initialize(name_or_ref, expressions)
        @name_or_ref = name_or_ref
        @expressions = expressions
        @expressions << self
      end

      def prefix
        " RETURN"
      end

      def to_s
        @name_or_ref.is_a?(Symbol) ? @name_or_ref.to_s : @name_or_ref.var_name
      end
    end


    class MatchRelLeft
      attr_reader :left, :right, :dir, :expressions

      def initialize(left, right, expressions, dir)
        @left = left
        @right = right.first
        @expressions = expressions
        @dir = dir
        @expressions << self
      end

      def prefix
        " MATCH"
      end

      def >>(other)
        MatchRelRight.new(other, expressions, dir)
      end

      def var_name_for(v) # TODO DRY
        v.respond_to?(:var_name) ? v.var_name : v.to_s
      end

      def to_s
        "(#{var_name_for(left)})-[#{var_name_for(right)}]"
      end
    end

    class MatchRelRight
      attr_reader :right, :dir_op

      def initialize(right, expressions, dir)
        @right = right
        @expressions = expressions
        @dir_op = case dir
                    when :outgoing then
                      "->"
                    when :incoming then
                      "<-"
                    when :both then
                      "-"
                  end
        @expressions << self
      end

      def prefix
        " MATCH"
      end

      def var_name_for(v) # TODO DRY
        v.respond_to?(:var_name) ? v.var_name : v.to_s
      end

      def to_s
        "#{dir_op}(#{var_name_for(right)})"
      end
    end

    class Match
      attr_reader :left, :right, :dir_op

      def initialize(left, right, expressions, dir)
        @left = left
        @right = right
        @expressions = expressions
        @dir_op = case dir
                    when :outgoing then
                      "-->"
                    when :incoming then
                      "<--"
                    when :both then
                      "--"
                  end
        @expressions << self
      end

      def prefix
        " MATCH"
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


    def match(*)
      self
    end

    def start(*)
      self
    end

    def query(index_class, q, index_type = :exact)
      NodeQuery.new(index_class, q, index_type, @expressions)
    end

    def lookup(index_class, key, value)
      NodeLookup.new(index_class, key, value, @expressions)
    end

    def node(*nodes)
      StartNode.new(nodes, @expressions)
    end

    def rel(*rels)
      StartRel.new(rels, @expressions)
    end

    def ret(*returns)
      returns.each { |ret| Return.new(ret, @expressions) }
      @expressions.last
    end

    def to_s
      curr_prefix = nil
      @expressions.map do |expr|
        separator = expr.kind_of?(MatchRelRight) ? "" : ","  # TODO ugly
        expr_to_s = expr.prefix != curr_prefix ? "#{expr.prefix} #{expr.to_s}" : "#{separator}#{expr.to_s}"
        curr_prefix = expr.prefix
        expr_to_s
      end.join
    end
  end
end