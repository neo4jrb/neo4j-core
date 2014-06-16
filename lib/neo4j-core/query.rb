require 'neo4j-core/query_clauses'

module Neo4j::Core
  class Query
    include Neo4j::Core::QueryClauses

    def initialize(options = {})
      @options = options
      @clauses = []
    end

    def start(*args)
      build_deeper_query(StartClause, *args)
    end

    def match(*args)
      build_deeper_query(MatchClause, *args)
    end

    def where(*args)
      build_deeper_query(WhereClause, *args)
    end

    def with(*args)
      build_deeper_query(WithClause, *args)
    end

    def order(*args)
      build_deeper_query(OrderClause, *args)
    end

    def limit(*args)
      build_deeper_query(LimitClause, *args)
    end

    def skip(*args)
      build_deeper_query(SkipClause, *args)
    end
    alias_method :offset, :skip

    def return(*args)
      build_deeper_query(ReturnClause, *args)
    end

    def create(*args)
      build_deeper_query(CreateClause, *args)
    end

    def to_cypher
      cypher_string = clauses_partitioned_by_withs.map do |with_clauses, clauses|
        clauses_by_class = clauses.group_by(&:class)

        cypher_parts = []
        cypher_parts << WithClause.to_cypher(with_clauses) unless with_clauses.empty?
        cypher_parts += [CreateClause, StartClause, MatchClause, WhereClause, ReturnClause, OrderClause, LimitClause, SkipClause].map do |clause_class|
          clauses = clauses_by_class[clause_class]

          clause_class.to_cypher(clauses) if clauses
        end

        cypher_string = cypher_parts.compact.join(' ')
        cypher_string.strip
      end.join ' '

      cypher_string = "CYPHER #{@options[:parser]} #{cypher_string}" if @options[:parser]
      cypher_string.strip
    end

    protected

    def add_clauses(clauses)
      @clauses += clauses
    end

    private

    def build_deeper_query(clause_class, *args)
      self.dup.tap do |new_query|
        new_query.add_clauses clause_class.from_args(args)
      end
    end

    def clauses_partitioned_by_withs
      # Each element of this array contains the with clauses and the clauses that follow them
      partitioning = [[[], []]]

      last_was_with = false
      @clauses.each do |clause|
        is_with = clause.is_a?(WithClause)

        if is_with
          partitioning << [[], []] if not last_was_with
          partitioning.last.first << clause
        else
          partitioning.last.last  << clause
        end

        last_was_with = is_with
      end

      partitioning.pop if partitioning.last == [[], []]

      partitioning
    end
  end
end



