module Neo4j
  # A label is a named graph construct that is used to group nodes.
  # See Neo4j::Node how to create and delete nodes
  # @see http://docs.neo4j.org/chunked/milestone/graphdb-neo4j-labels.html
  class Label
    class InvalidQueryError < StandardError; end

    # @abstract
    def name
      raise 'not implemented'
    end

    # @abstract
    def create_index(*properties)
      raise 'not implemented'
    end

    # @abstract
    def drop_index(*properties)
      raise 'not implemented'
    end

    # List indices for a label
    # @abstract
    def indexes
      raise 'not implemented'
    end

    # Creates a neo4j constraint on a property
    # See http://docs.neo4j.org/chunked/stable/query-constraints.html
    # @example
    #   label = Neo4j::Label.create(:person, session)
    #   label.create_constraint(:name, {type: :unique}, session)
    #
    def create_constraint(property, constraints, session = Neo4j::Session.current)
      cypher = case constraints[:type]
        when :unique
          "CREATE CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
        else
          raise "Not supported constrain #{constraints.inspect} for property #{property} (expected :type => :unique)"
      end
      session._query_or_fail(cypher)
    end

    # Drops a neo4j constraint on a property
    # See http://docs.neo4j.org/chunked/stable/query-constraints.html
    # @example
    #   label = Neo4j::Label.create(:person, session)
    #   label.create_constraint(:name, {type: :unique}, session)
    #   label.drop_constraint(:name, {type: :unique}, session)
    #
    def drop_constraint(property, constraint, session = Neo4j::Session.current)
      cypher = case constraint[:type]
                 when :unique
                   "DROP CONSTRAINT ON (n:`#{name}`) ASSERT n.`#{property}` IS UNIQUE"
                 else
                   raise "Not supported constrain #{constraint.inspect}"
               end
      session._query_or_fail(cypher)
    end

    class << self
      include Neo4j::Core::CypherTranslator

      # Returns a label of given name that can be used to specifying constraints
      # @param [Symbol,String] name the name of the label
      def create(name, session = Neo4j::Session.current)
        session.create_label(name)
      end

      # Performs a cypher query from given label.
      #
      # @param [Symbol,String] label_name the label we want to query.do
      # @param [Hash] query the cypher query
      # @option query [Symbol,String] :as (:n) the default parameter in the cypher query to use.
      # @option query [Hash] :conditions key and value of properties which the label nodes must match
      # @option query [String, Array] :match the cypher match clause
      # @option query [String, Array] :where the cypher where clause
      # @option query [String, Array, Symbol] :return the cypher where clause
      # @option query [String,Symbol,Array<Hash>] :order the order
      # @option query [Fixnum] :limit limits the return
      # @return [Enumerable<Neo4j::Node>] the result, can also be wrapped in your own model ruby classes.
      #
      # @example using conditions
      #   Neo4j::Label.query(:person, conditions: {name: 'jimmy', age: 42}) # => "MATCH (n:`person`) WHERE n.name='jimmy' AND n.age=42 RETURN ID(n)"
      #
      # @example order
      #   Neo4j::Label.query(:person, order: :name) # => "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name`"
      #   Neo4j::Label.query(:person, order: {name: :desc}) # => "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name` DESC"
      #   Neo4j::Label.query(:person, order: [{name: :desc}, :age]) # => MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name` DESC, n.`age`"
      #
      # @example match, notice :n is the default value which can be overridden by :as parameter
      #   Neo4j::Label.query(:person, match: 'n-[:friends]->o') # =>  "MATCH (n:`person`),n-[:friends]->o"
      #   Neo4j::Label.query(:person, match: ['n-[:friends]->o','n--m']) # => "MATCH (n:`person`),n-[:friends]->o,n--m RETURN ID(n)"
      #
      # @example using limit
      #   Neo4j::Label.query(:person, limit: 50) #  # => "MATCH (n:`person`),n-[:friends]->o RETURN ID(n) LIMIT 50"
      #
      # @note When using a Neo4j server session this method will internally generate cypher queries returning IDs of each node. When using an embedded session, this method will internally generate cypher queries directly returning nodes (which is probably faster).
      #
      def query(label_name, query, session = Neo4j::Session.current)
        as = query[:as] || 'n'
        cypher = cypher_match(label_name, query, as)
        cypher += cypher_where(query[:conditions], as) if query[:conditions] && !query[:conditions].empty?
        cypher += cypher_where(query[:where], as) if query[:where] && !query[:where].empty?
        cypher += cypher_return(query[:return],as) if query[:return]
        cypher += session.query_default_return(as) unless query[:return]
        cypher += order_to_cypher(query, as) if query[:order]
        cypher += " LIMIT " + query[:limit].to_s if query[:limit] && query[:limit].is_a?(Integer)

        cypher_query(cypher, session)
      end

      def cypher_query(query, session = Neo4j::Session.current)
        response = session._query_or_fail(query)
        session.search_result_to_enumerable(response) # TODO make it work in Embedded and refactor
      end

      # @return [Enumerable<Neo4j::Node>] all nodes having given label. Nodes can be wrapped in your own model ruby classes.
      def find_all_nodes(label_name, session = Neo4j::Session.current)
        session.find_all_nodes(label_name)
      end

      # @return [Enumerable<Neo4j::Node>] all nodes having given label and properties. Nodes can be wrapped in your own model ruby classes.
      def find_nodes(label_name, key, value, session = Neo4j::Session.current)
        session.find_nodes(label_name, key, value)
      end

      private

      def cypher_return(ret, as)
        case ret
          when Array
            " RETURN #{ret.map{|r| "#{as}.`#{r}`"}.join(',')}"
          when String
            " RETURN #{ret}"
          else Symbol
          " RETURN #{as}.`#{ret}`"
        end

      end

      def cypher_match(label_name, query, as)
        parts = ["MATCH (#{as}:`#{label_name}`)"]

        # TODO: Injection vulnerability?
        case query[:match]
        when Array
          parts += query[:match]
        when String
          parts << query[:match]
        when NilClass
        else
          raise InvalidQueryError, "Invalid value for 'match' query key"
        end

        parts.join(',')
      end

      def cypher_where(conditions, as)
        parts = if (conditions.is_a?(Hash))
                  hash_to_where_clause(as, conditions)
                else
                  conditions.is_a?(Array) ? conditions: [conditions]
                end

        " WHERE " + parts.join(" AND ")
      end

      def hash_to_where_clause(as, conditions)
        neo_id = conditions.delete(:neo_id)
        conditions["id(#{as})"] = neo_id if neo_id

        conditions.map do |key, value|
          operator, value_string = case value
                                     when Regexp
                                       pattern = (value.casefold? ? "(?i)" : "") + value.source
                                       ['=~', escape_value(pattern.gsub(/\\/, '\\\\\\'))]
                                     else
                                       ['=', escape_value(value)]
                                   end

          k = key.to_s.dup
          k = "#{as}.#{k}" unless k.match(/[\(\.]/)
          k + operator + value_string.to_s
        end
      end

      def order_to_cypher(query, as)
        cypher = " ORDER BY "
        order = query[:order]

        handleHash = Proc.new do |hash|
          if (hash.is_a?(Hash))
            k, v = hash.first
            raise "only :asc or :desc allowed in order, got #{query.inspect}" unless [:asc, :desc].include?(v)
            v.to_sym == :asc ? "#{as}.`#{k}`" : "#{as}.`#{k}` DESC"
          else
            "#{as}.`#{hash}`" unless hash.is_a?(Hash)
          end
        end

        case order
          when Array
            cypher += order.map(&handleHash).join(', ')
          when Hash
            cypher += handleHash.call(order)
          else
            cypher += "#{as}.`#{order}`"
        end

        cypher
      end
    end

  end

end
