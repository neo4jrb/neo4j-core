require 'neo4j-core/query_clauses'
require 'active_support/notifications'

module Neo4j
  module Core
    # Allows for generation of cypher queries via ruby method calls (inspired by ActiveRecord / arel syntax)
    #
    # Can be used to express cypher queries in ruby nicely, or to more easily generate queries programatically.
    #
    # Also, queries can be passed around an application to progressively build a query across different concerns
    #
    # See also the following link for full cypher language documentation:
    # http://docs.neo4j.org/chunked/milestone/cypher-query-lang.html
    class Query
      include Neo4j::Core::QueryClauses
      include Neo4j::Core::QueryFindInBatches
      DEFINED_CLAUSES = {}

      def initialize(options = {})
        @session = options[:session] || Neo4j::Session.current

        @options = options
        @clauses = []
        @_params = {}
      end

      # @method start *args
      # START clause
      # @return [Query]

      # @method match *args
      # MATCH clause
      # @return [Query]

      # @method optional_match *args
      # OPTIONAL MATCH clause
      # @return [Query]

      # @method using *args
      # USING clause
      # @return [Query]

      # @method where *args
      # WHERE clause
      # @return [Query]

      # @method with *args
      # WITH clause
      # @return [Query]

      # @method order *args
      # ORDER BY clause
      # @return [Query]

      # @method limit *args
      # LIMIT clause
      # @return [Query]

      # @method skip *args
      # SKIP clause
      # @return [Query]

      # @method set *args
      # SET clause
      # @return [Query]

      # @method remove *args
      # REMOVE clause
      # @return [Query]

      # @method unwind *args
      # UNWIND clause
      # @return [Query]

      # @method return *args
      # RETURN clause
      # @return [Query]

      # @method create *args
      # CREATE clause
      # @return [Query]

      # @method create_unique *args
      # CREATE UNIQUE clause
      # @return [Query]

      # @method merge *args
      # MERGE clause
      # @return [Query]

      # @method on_create_set *args
      # ON CREATE SET clause
      # @return [Query]

      # @method on_match_set *args
      # ON MATCH SET clause
      # @return [Query]

      # @method delete *args
      # DELETE clause
      # @return [Query]

      METHODS = %w(start match optional_match using where create create_unique merge set on_create_set on_match_set remove unwind delete with return order skip limit)
      BREAK_METHODS = %(with)

      CLAUSIFY_CLAUSE = proc do |method|
        const_get(method.to_s.split('_').map(&:capitalize).join + 'Clause')
      end

      CLAUSES = METHODS.map(&CLAUSIFY_CLAUSE)

      METHODS.each_with_index do |clause, i|
        clause_class = CLAUSES[i]

        DEFINED_CLAUSES[clause.to_sym] = clause_class
        define_method(clause) do |*args|
          build_deeper_query(clause_class, args).ergo do |result|
            BREAK_METHODS.include?(clause) ? result.break : result
          end
        end
      end

      alias_method :offset, :skip
      alias_method :order_by, :order

      # Clears out previous order clauses and allows only for those specified by args
      def reorder(*args)
        query = copy

        query.remove_clause_class(OrderClause)
        query.order(*args)
      end

      # Works the same as the #set method, but when given a nested array it will set properties rather than setting entire objects
      # @example
      #    # Creates a query representing the cypher: MATCH (n:Person) SET n.age = 19
      #    Query.new.match(n: :Person).set_props(n: {age: 19})
      def set_props(*args)
        build_deeper_query(SetClause, args, set_props: true)
      end

      # Allows what's been built of the query so far to be frozen and the rest built anew.  Can be called multiple times in a string of method calls
      # @example
      #   # Creates a query representing the cypher: MATCH (q:Person), r:Car MATCH (p: Person)-->q
      #   Query.new.match(q: Person).match('r:Car').break.match('(p: Person)-->q')
      def break
        build_deeper_query(nil)
      end

      # Allows for the specification of values for params specified in query
      # @example
      #   # Creates a query representing the cypher: MATCH (q: Person {id: {id}})
      #   # Calls to params don't affect the cypher query generated, but the params will be
      #   # Passed down when the query is made
      #   Query.new.match('(q: Person {id: {id}})').params(id: 12)
      #
      def params(args)
        @_params = @_params.merge(args)

        self
      end

      def unwrapped
        @_unwrapped_obj = true
        self
      end

      def unwrapped?
        !!@_unwrapped_obj
      end

      def response
        return @response if @response
        cypher = to_cypher
        @response = ActiveSupport::Notifications.instrument('neo4j.cypher_query', context: @options[:context] || 'CYPHER', cypher: cypher, params: merge_params) do
          @session._query(cypher, merge_params)
        end
        if !response.respond_to?(:error?) || !response.error?
          response
        else
          response.raise_cypher_error
        end
      end

      include Enumerable

      def count(var = nil)
        v = var.nil? ? '*' : var
        pluck("count(#{v})").first
      end

      def each
        response = self.response
        if response.is_a?(Neo4j::Server::CypherResponse)
          response.unwrapped! if unwrapped?
          response.to_node_enumeration
        else
          Neo4j::Embedded::ResultWrapper.new(response, to_cypher, unwrapped?)
        end.each { |object| yield object }
      end

      # @method to_a
      # Class is Enumerable.  Each yield is a Hash with the key matching the variable returned and the value being the value for that key from the response
      # @return [Array]
      # @raise [Neo4j::Server::CypherResponse::ResponseError] Raises errors from neo4j server


      # Executes a query without returning the result
      # @return [Boolean] true if successful
      # @raise [Neo4j::Server::CypherResponse::ResponseError] Raises errors from neo4j server
      def exec
        response

        true
      end

      # Return the specified columns as an array.
      # If one column is specified, a one-dimensional array is returned with the values of that column
      # If two columns are specified, a n-dimensional array is returned with the values of those columns
      #
      # @example
      #    Query.new.match(n: :Person).return(p: :name}.pluck(p: :name) # => Array of names
      # @example
      #    Query.new.match(n: :Person).return(p: :name}.pluck('p, DISTINCT p.name') # => Array of [node, name] pairs
      #
      def pluck(*columns)
        fail ArgumentError, 'No columns specified for Query#pluck' if columns.size.zero?

        query = return_query(columns)
        columns = query.response.columns

        case columns.size
        when 1
          column = columns[0]
          query.map { |row| row[column] }
        else
          query.map do |row|
            columns.map do |column|
              row[column]
            end
          end
        end
      end

      def return_query(columns)
        query = copy
        query.remove_clause_class(ReturnClause)

        query.return(*columns)
      end

      # Returns a CYPHER query string from the object query representation
      # @example
      #    Query.new.match(p: :Person).where(p: {age: 30})  # => "MATCH (p:Person) WHERE p.age = 30
      #
      # @return [String] Resulting cypher query string
      def to_cypher
        cypher_string = PartitionedClauses.new(@clauses).map do |clauses|
          clauses_by_class = clauses.group_by(&:class)

          cypher_parts = CLAUSES.map do |clause_class|
            clause_class.to_cypher(clauses) if clauses = clauses_by_class[clause_class]
          end

          cypher_parts.compact.join(' ').strip
        end.join ' '

        cypher_string = "CYPHER #{@options[:parser]} #{cypher_string}" if @options[:parser]
        cypher_string.strip
      end

      # Returns a CYPHER query specifying the union of the callee object's query and the argument's query
      #
      # @example
      #    # Generates cypher: MATCH (n:Person) UNION MATCH (o:Person) WHERE o.age = 10
      #    q = Neo4j::Core::Query.new.match(o: :Person).where(o: {age: 10})
      #    result = Neo4j::Core::Query.new.match(n: :Person).union_cypher(q)
      #
      # @param other [Query] Second half of UNION
      # @param options [Hash] Specify {all: true} to use UNION ALL
      # @return [String] Resulting UNION cypher query string
      def union_cypher(other, options = {})
        "#{to_cypher} UNION#{options[:all] ? ' ALL' : ''} #{other.to_cypher}"
      end

      def &(other)
        fail "Sessions don't match!" if @session != other.session

        self.class.new(session: @session).tap do |new_query|
          new_query.options = options.merge(other.options)
          new_query.clauses = clauses + other.clauses
        end.params(other._params)
      end

      MEMOIZED_INSTANCE_VARIABLES = [:response, :merge_params]
      def copy
        dup.tap do |query|
          MEMOIZED_INSTANCE_VARIABLES.each do |var|
            query.instance_variable_set("@#{var}", nil)
          end
        end
      end

      def clause?(method)
        clause_class = DEFINED_CLAUSES[method] || CLAUSIFY_CLAUSE.call(method)
        clauses.any? do |clause|
          clause.is_a?(clause_class)
        end
      end

      protected

      attr_accessor :session, :options, :clauses, :_params

      def add_clauses(clauses)
        @clauses += clauses
      end

      def remove_clause_class(clause_class)
        @clauses = @clauses.reject do |clause|
          clause.is_a?(clause_class)
        end
      end

      private

      def build_deeper_query(clause_class, args = {}, options = {})
        copy.tap do |new_query|
          new_query.add_clauses [nil] if [nil, WithClause].include?(clause_class)
          new_query.add_clauses clause_class.from_args(args, options) if clause_class
        end
      end

      class PartitionedClauses
        def initialize(clauses)
          @clauses = clauses
          @partitioning = [[]]
        end

        include Enumerable

        def each
          generate_partitioning!

          @partitioning.each { |partition| yield partition }
        end

        def generate_partitioning!
          @partitioning = [[]]

          @clauses.each do |clause|
            if clause.nil? && !fresh_partition?
              @partitioning << []
            elsif clause_is_order_directly_following_with?(clause)
              second_to_last << clause
            elsif clause_is_with_following_order?(clause)
              second_to_last << clause
              second_to_last.sort_by! { |c| c.is_a?(::Neo4j::Core::QueryClauses::OrderClause) ? 1 : 0 }
            else
              @partitioning.last << clause
            end
          end
        end

        private

        def fresh_partition?
          @partitioning.last == []
        end

        def second_to_last
          @partitioning[-2]
        end

        def clause_is_order_directly_following_with?(clause)
          clause.is_a?(::Neo4j::Core::QueryClauses::OrderClause) &&
            @partitioning[-2] && @partitioning[-2].last.is_a?(::Neo4j::Core::QueryClauses::WithClause)
        end

        def clause_is_with_following_order?(clause)
          clause.is_a?(::Neo4j::Core::QueryClauses::WithClause) &&
            @partitioning[-2] && @partitioning[-2].any? { |c| c.is_a?(::Neo4j::Core::QueryClauses::OrderClause) }
        end
      end

      def merge_params
        @merge_params ||= @clauses.compact.inject(@_params) { |params, clause| params.merge(clause.params) }
      end
    end
  end
end
