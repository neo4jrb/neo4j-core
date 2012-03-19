module Neo4j
  class Cypher
    attr_reader :expressions

    include Neo4j::Core::Cypher
    include Neo4j::Core::Cypher::MathFunctions

    # Creates a Cypher DSL query.
    # To create a new cypher query you must initialize it either an String or a Block.
    #
    # @example <tt>START n0=node(3) MATCH (n0)--(x) RETURN x</tt> same as
    #   Cypher.new { start n = node(3); match n <=> :x; ret :x }.to_s
    #
    # @example <tt>START n0=node(3) MATCH (n0)-[r]->(x) RETURN r</tt> same as
    #   node(3) > :r > :x; :r
    #
    # @example <tt>START n0=node(3) MATCH (n0)-->(x) RETURN x</tt> same as
    #   node(3) >> :x; :x
    #
    # @param args the argument for the dsl_block
    # @yield the block which will be evaluated in the context of this object in order to create an Cypher Query string
    # @yieldreturn [Return, Object] If the return is not an instance of Return it will be converted it to a Return object (if possible).
    def initialize(*args, &dsl_block)
      @expressions = []
      @variables = []
      res = self.instance_exec(*args, &dsl_block)
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

    def where(w=nil)
      Where.new(@expressions, w) if w.is_a?(String)
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
        NodeVar.new(@expressions, @variables).as(nodes.first)
      elsif !nodes.empty?
        StartNode.new(nodes, @expressions)
      else
        NodeVar.new(@expressions, @variables)
      end
    end

    # Similar to #node
    # @return [StartRel, RelVar]
    def rel(*rels)
      if rels.first.is_a?(Fixnum) || rels.first.respond_to?(:neo_id)
        StartRel.new(rels, @expressions)
      elsif rels.first.is_a?(Symbol)
        RelVar.new(@expressions, @variables, "").as(rels.first)
      elsif rels.first.is_a?(String)
        RelVar.new(@expressions, @variables, rels.first)
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
      options = returns.last.is_a?(Hash) ? returns.pop : {}
      @expressions -= @expressions.find_all { |r| r.clause == :return && returns.include?(r) }
      returns.each { |ret| Return.new(ret, @expressions, options) unless ret.respond_to?(:clause) && [:order_by, :skip, :limit].include?(ret.clause)}
      @expressions.last
    end

    def shortest_path(&block)
      match = instance_eval(&block)
      match.algorithm = 'shortestPath'
      match.find_match_start
    end

    def shortest_paths(&block)
      match = instance_eval(&block)
      match.algorithm = 'shortestPaths'
      match.find_match_start
    end

    # @param [Symbol,nil] variable the entity we want to count or wildcard (*)
    # @return [Return] a counter return clause
    def count(variable='*')
      Return.new("count(#{variable.to_s})", @expressions)
    end

    def coalesce(*args)
      s = args.map { |x| x.var_name }.join(", ")
      Return.new("coalesce(#{s})", @expressions)
    end

    def nodes(*args)
      s = args.map { |x| x.referenced!; x.var_name }.join(", ")
      Return.new("nodes(#{s})", @expressions)
    end

    def rels(*args)
      s = args.map { |x| x.referenced!; x.var_name }.join(", ")
      Return.new("relationships(#{s})", @expressions)
    end

    # Converts the DSL query to a cypher String which can be executed by cypher query engine.
    def to_s
      clause = nil
      @expressions.map do |expr|
        next unless expr.valid?
        expr_to_s = expr.clause != clause ? "#{expr.prefix} #{expr.to_s}" : "#{expr.separator}#{expr.to_s}"
        clause = expr.clause
        expr_to_s
      end.join
    end

  end
end
