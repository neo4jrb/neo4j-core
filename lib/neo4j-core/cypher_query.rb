module Neo4j::Core
  class CypherQuery
    attr_reader :nodes, :rels #[QueryElement]
    attr_accessor :str

    CYPHER_CLAUSES = {start: ',',
                      match: nil,
                      where: ' AND ',
                      return: ',',
                      order: ','}

    def initialize(match={}) #match for backwards compatibility
      @nodes = [QueryElement.new(:n)] #default available for backwards compatibility
      @rels = []

      _backwards_compatible(match) if match.first
      self
    end

    def _backwards_compatible(match={})
      rels(:r).dir = match[:dir] if match[:dir]
      rels(:r).rel_type = match[:rel_type] if match[:rel_type]
      nodes(:n).id = match[:neo_id] if match[:neo_id]
      nodes(:n).labels = match[:neo_labels] if match[:neo_labels]
      nodes(:p).id = match[:between_id] if match[:between_id]
      nodes(:p).labels = match[:between_labels] if match[:between_labels]
      if match[:between]
        nodes(:p).id = match[:between].neo_id
        nodes(:p).labels = match[:between].labels
      end
    end

    def nodes(var_name=nil)
      if var_name
        unless node = nodes.select{|n| n.var_name == var_name}[0]
          node = QueryElement.new(var_name)
          @nodes << node
        end
        node
      else
        @nodes
      end
    end

    def rels(var_name=nil)
      if var_name
        unless rel = rels.select{|r| r.var_name == var_name}[0]
          rel = QueryElement.new(var_name, true)
          @rels << rel
        end
        rel
      else
        @rels
      end
    end


    def elements(overwrite=false)
      return @els if @els && !overwrite

      @els = []
      if nodes.length > 1
        nodes.length.times do |i|
          @els << nodes[i]
          if rel = rels[i]
            @els << rel
          elsif i < nodes.length - 1
            @els << rels("r#{i}")
          end
        end
      else
        @els << ((rels.length > 0) ? rels[0] : nodes[0])
      end

      @els = @els.compact
    end

    def element(var_name)
      nodes.select{|n| n.var_name == var_name}[0] ||
      rels.select{|r| r.var_name == var_name}[0] || 
      nodes(var_name)
    end

    def id(var_name, id)
      if el = element(var_name)
        el.id = id
      end
      self
    end

    def returns(var_name, func)
      if el = element(var_name)
        el.returns = func
      end
      self
    end

    def print_clause(clause)
      els = elements(true)

      if contents = els.map{|el| el.print_clause(clause)}.compact and
        !contents.empty?
        "#{clause.to_s.upcase} #{contents.join(CYPHER_CLAUSES[clause])}"
      end
    end

    def to_s(overwrite=false)
      str = nil if overwrite
      str ||= CYPHER_CLAUSES.keys.map{|c| print_clause(c)}.join(' ')
    end
  end
end
