module Neo4j
  class Session

    @@current_session = nil
    @@all_sessions = {}
    @@factories = {}

    # @abstract
    def close
      self.class.unregister(self)
    end

    # Only for embedded database
    # @abstract
    def start
      raise "not impl."
    end

    # Only for embedded database
    # @abstract
    def shutdown
      raise "not impl."
    end

    # Only for embedded database
    # @abstract
    def running
      raise "not impl."
    end

    def auto_commit?
      true # TODO
    end

    # @abstract
    def begin_tx
      raise "not impl."
    end

    class CypherError < StandardError
      attr_reader :error_msg, :error_status, :error_code
      def initialize(error_msg, error_code, error_status)
        super(error_msg)
        @error_msg = error_msg
        @error_status = error_status
      end
    end

    # Executes a Cypher Query
    # Returns an enumerable of hash values where each hash corresponds to a row unless <tt>return</tt> or <tt>map_return</tt>
    # is not an array. The search result can be mapped to Neo4j::Node or Neo4j::Relationship is your own Ruby wrapper class
    # by specifying a map_return parameter.
    #
    # @param [Hash, String] q the cypher query, as a pure string query or a hash which will generate a cypher string.
    # @option q [Hash] :params cypher parameters
    # @option q [Symbol,Hash] :label the label to match. You can specify several labels by using a hash of variable names and labels.
    # @option q [Symbol] :conditions key and value of properties which the label nodes must match
    # @option q [Hash] :conditions key and value of properties which the label nodes must match
    # @option q [String, Array] :match the cypher match clause
    # @option q [String, Array] :where the cypher where clause
    # @option q [String, Array, Symbol] :return the cypher where clause
    # @option q [String, Hash, Symbol] :map_return mapping of the returned values, e.g. :id_to_node, :id_to_rel, or :value
    # @option q [Hash<Symbol, Proc>] :map_return_procs custom mapping functions of :map_return types
    # @option q [String,Symbol,Array<Hash>] :order the order
    # @option q [Fixnum] :limit enables the return of only subsets of the total result.
    # @option q [Fixnum] :skip enables the return of only subsets of the total result.
    # @return [Enumerable] the result, an enumerable of Neo4j::Node objects unless a pure cypher string is given or return/map_returns is specified, see examples.
    # @raise CypherError if invalid cypher
    # @example Cypher String and parameters
    #   Neo4j::Session.query("START n=node({p}) RETURN ID(n)", params: {p: 42})
    #
    # @example label
    #   # If there is no :return parameter it will try to return Neo4j::Node objects
    #   # Default parameter is :n in the generated cypher
    #   Neo4j::Session.query(label: :person) # => MATCH (n:`person`) RETURN ID(n) # or RETURN n for embedded
    #
    # @example to_s
    #   # What Cypher is returned ? check with to_s
    #   Neo4j::Session.query(label: :person).to_s # =>
    #
    # @example return
    #   Neo4j::Session.query(label: :person, return: :age)  # returns age properties
    #   Neo4j::Session.query(label: :person, return: [:name, :age]) # returns a hash of name and age properties
    #   Neo4j::Session.query(label: :person, return: 'count(n) AS c')
    #
    # @example map_return
    #   Neo4j::Session.query("START n=node(42) RETURN n.name", map_return: :value) #=> an Enumerable of names
    #   Neo4j::Session.query("START n=node(42) MATCH n-[r]->[x] RETURN n.name as N, ID(r) as R, ID(x) as X", map_return: {N: :value, R: :id_to_rel, X: :id_to_node}]) #=> an Enumerable of an Hash with name property, Neo4j::Relationship and Neo4j::Node
    #   Neo4j::Session.query("START n=node(42) MATCH n-[r]->[x] RETURN n.name as N, r, x", map_return: {N: :value, r: :to_rel, x: :to_node}) #=> same as above, but for the embedded database
    #
    # @example map_return_procs, custom mapping function
    #   Neo4j::Session.query(label: :person, map_return: :age_times_two, map_return_procs: {age_times_two: ->(row){(row[:age] || 0) * 2}})
    #
    # @example match
    #   Neo4j::Session.query(label: :person, match: 'n--m')
    #
    # @example where
    #   Neo4j::Session.query(label: :person, where: 'n.age > 40')
    #   Neo4j::Session.query(label: :person, where: 'n.age > {age}', params: {age: 40})
    #
    # @example condition
    #   Neo4j::Session.query(label: :person, conditions: {age: 42})
    #   Neo4j::Session.query(label: :person, conditions: {name: /foo?bar.*/})
    #
    # @see http://docs.neo4j.org/chunked/milestone/cypher-query-lang.html The Cypher Query Language Documentation
    # @note Returns a read-once only forward iterable for the embedded database.
    #
    def query(q)
      raise 'not implemented, abstract'
    end

    # Same as #query but does not accept an DSL and returns the raw result from the database.
    # Notice, it might return different values depending on which database is used, embedded or server.
    # @abstract
    def _query(*params)
      raise 'not implemented'
    end

    class << self
      # Creates a new session to Neo4j
      # @see also Neo4j::Server::CypherSession#open for :server_db params
      # @param db_type the type of database, e.g. :embedded_db, or :server_db
      def open(db_type=:server_db, *params)
        register(create_session(db_type, params))
      end

      def open_named(db_type, name, default = nil, *params)
        raise "Multiple sessions is currently only supported for Neo4j Server connections." unless db_type == :server_db
        register(create_session(db_type, params), name, default)
      end

      def create_session(db_type, params = {})
        unless (@@factories[db_type])
          raise "Can't connect to database '#{db_type}', available #{@@factories.keys.join(',')}"
        end
        @@factories[db_type].call(*params)
      end

      def current
        @@current_session
      end

      # @see Neo4j::Session#query
      def query(*params)
        current.query(*params)
      end

      def named(name)
        @@all_sessions[name] || raise("No session named #{name}.")
      end

      def set_current(session)
        @@current_session = session
      end

      def add_listener(&listener)
        self._listeners << listener
      end

      def _listeners
        @@listeners ||= []
        @@listeners
      end

      def _notify_listeners(event, data)
        _listeners.each {|li| li.call(event, data)}
      end

      def register(session, name = nil, default = nil)
        if default == true
          set_current(session)
        elsif default.nil?
          set_current(session) unless @@current_session
        end
        @@all_sessions[name] = session if name
        @@current_session
      end

      def unregister(session)
        @@current_session = nil if @@current_session == session
      end

      def register_db(db, &session_factory)
        raise "Factory for #{db} already exists" if @@factories[db]
        @@factories[db] = session_factory
      end
    end
  end
end
