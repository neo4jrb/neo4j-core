require 'neo4j-core/query_clauses'

module Neo4j::Core
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

    def initialize(options = {})
      @session = options[:session] || Neo4j::Session.current

      @options = options
      @clauses = []
      @params = {}
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

    METHODS = %w[with start match optional_match using where set create create_unique merge on_create_set on_match_set remove unwind delete return order skip limit]

    CLAUSES = METHODS.map {|method| const_get(method.split('_').map {|c| c.capitalize }.join + 'Clause') }

    METHODS.each_with_index do |clause, i|
      clause_class = CLAUSES[i]

      module_eval(%Q{
        def #{clause}(*args)
          build_deeper_query(#{clause_class}, args)
        end}, __FILE__, __LINE__)
    end

    alias_method :offset, :skip
    alias_method :order_by, :order

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
      @params = @params.merge(args)

      self
    end

    def response
      response = @session._query(self.to_cypher, @params)
      if !response.respond_to?(:error?) || !response.error?
        response
      else
        response.raise_cypher_error
      end
    end

    include Enumerable

    def each
      response = self.response
      if response.is_a?(Neo4j::Server::CypherResponse)
        self.response.to_node_enumeration
      else
        Neo4j::Embedded::ResultWrapper.new(response, {}, self.to_cypher)
      end.each {|object| yield object }
    end

    # @method to_a
    # Class is Enumerable.  Each yield is a Hash with the key matching the variable returned and the value being the value for that key from the response
    # @return [Array]
    # @raise [Neo4j::Server::CypherResponse::ResponseError] Raises errors from neo4j server


    # Executes a query without returning the result
    # @return [Boolean] true if successful
    # @raise [Neo4j::Server::CypherResponse::ResponseError] Raises errors from neo4j server
    def exec
      self.response

      true
    end

    # Return the specified columns as an array.
    # If one column is specified, a one-dimensional array is returned with the values of that column
    # If two columns are specified, a n-dimensional array is returned with the values of those columns
    #
    # @example
    #    Query.new.match(n: :Person).return(p: :name}.pluck(p: :name) # => Array of names
    # @example
    #    Query.new.match(n: :Person).return(p: :name}.pluck('p, p.name') # => Array of [node, name] pairs
    #
    def pluck(*columns)
      query = self.dup
      query.remove_clause_class(ReturnClause)

      columns = columns.map do |column_definition|
        if column_definition.is_a?(Hash)
          column_definition.map {|k, v| "#{k}.#{v}" }
        else
          column_definition
        end
      end.flatten.map(&:to_sym)

      query = query.return(columns)

      case columns.size
      when 0
        raise ArgumentError, 'No columns specified for Query#pluck'
      when 1
        column = columns[0]
        query.map {|row| row[column] }
      else
        query.map do |row|
          columns.map do |column|
            row[column]
          end
        end
      end
    end


    # Returns a CYPHER query string from the object query representation
    # @example
    #    Query.new.match(p: :Person).where(p: {age: 30})  # => "MATCH (p:Person) WHERE p.age = 30
    #
    # @return [String] Resulting cypher query string
    def to_cypher
      cypher_string = partitioned_clauses.map do |clauses|
        clauses_by_class = clauses.group_by(&:class)

        cypher_parts = CLAUSES.map do |clause_class|
          clauses = clauses_by_class[clause_class]

          clause_class.to_cypher(clauses) if clauses
        end

        cypher_string = cypher_parts.compact.join(' ')
        cypher_string.strip
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
    # @param other_query [Query] Second half of UNION
    # @param options [Hash] Specify {all: true} to use UNION ALL
    # @return [String] Resulting UNION cypher query string
    def union_cypher(other_query, options = {})
      "#{self.to_cypher} UNION#{options[:all] ? ' ALL' : ''} #{other_query.to_cypher}"
    end

    protected

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
      self.dup.tap do |new_query|
        new_query.add_clauses [nil] if [nil, WithClause].include?(clause_class)
        new_query.add_clauses clause_class.from_args(args, options) if clause_class
      end
    end

    def break_deeper_query
      self.dup.tap do |new_query|
        new_query.add_clauses [nil]
      end
    end

    def partitioned_clauses
      partitioning = [[]]

      @clauses.each do |clause|
        if clause.nil? && partitioning.last != []
          partitioning << []
        else
          partitioning.last << clause
        end
      end

      partitioning
    end
  end
end



