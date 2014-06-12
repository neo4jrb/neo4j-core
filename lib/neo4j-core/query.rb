require 'neo4j-core/query_conditions'

module Neo4j::Core
  class Query
    include Neo4j::Core::QueryConditions

    def initialize(options = {})
      @options = options
      @conditions = []
    end

    def start(*args)
      build_deeper_query(StartCondition, *args)
    end

    def match(*args)
      build_deeper_query(MatchCondition, *args)
    end

    def where(*args)
      build_deeper_query(WhereCondition, *args)
    end

    def order(*args)
      build_deeper_query(OrderCondition, *args)
    end

    def limit(*args)
      build_deeper_query(LimitCondition, *args)
    end

    def skip(*args)
      build_deeper_query(SkipCondition, *args)
    end
    alias_method :offset, :skip

    def return(*args)
      build_deeper_query(ReturnCondition, *args)
    end

    def create(*args)
      build_deeper_query(CreateCondition, *args)
    end

    def to_cypher
      conditions_by_class = @conditions.group_by(&:class)

      condition_string =
        [CreateCondition, StartCondition, MatchCondition, WhereCondition, ReturnCondition, OrderCondition, LimitCondition, SkipCondition].map do |condition_class|
          conditions = conditions_by_class[condition_class]

          condition_class.to_cypher(conditions) if conditions
        end.compact.join(' ')

      condition_string = "CYPHER #{@options[:parser]} #{condition_string}" if @options[:parser]

      condition_string.strip
    end

    protected

    def add_conditions(conditions)
      @conditions += conditions
    end

    private

    def build_deeper_query(condition_class, *args)
      self.dup.tap do |new_query|
        new_query.add_conditions condition_class.from_args(args)
      end
    end
  end
end


