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
    # Returns an enumerable of hash values, column => value
    #
    # @example Using the Cypher DSL
    #  q = Neo4j.query("START n=node({param}) RETURN n", :param => 0)
    #  q.first[:n] #=> the node
    #  q.columns.first => :n
    #
    # @example Using the Cypher DSL
    #  q = Neo4j.query{ match node(3) <=> node(:x); ret :x}
    #  q.first[:n] #=> the @node
    #  q.columns.first => :n
    #
    # @example Using the Cypher DSL and one parameter (n=Neo4j.ref_node)
    #  q = Neo4j.query(Neo4j.ref_node){|n| n <=> node(:x); :x}
    #  q.first[:n] #=> the @node
    #  q.columns.first => :n
    #
    # @example Using an array of nodes
    #  # same as - two_nodes=node(Neo4j.ref_node.neo_id, node_b.neo_id), b = node(b.neo_id)
    #  q = Neo4j.query([Neo4j.ref_node, node_b], node_c){|two_nodes, b| two_nodes <=> b; b}
    #
    # @see Cypher
    # @see http://docs.neo4j.org/chunked/milestone/cypher-query-lang.html The Cypher Query Language Documentation
    # @note Returns a read-once only forward iterable.
    # @param params parameter for the query_dsl block
    # @return [Neo4j::Cypher::ResultWrapper] a forward read once only Enumerable, containing hash values.
    #
    # @abstract
    def query(*params, &query_dsl)
      cypher_params = params.pop if params.last.is_a?(Hash)
      q = query_dsl ? Neo4j::Cypher.query(*params, &query_dsl).to_s : params[0]
      _query(q, cypher_params)
    end

    # Same as #query but does not accept an DSL and returns the raw result from the database.
    # Notice, it might return different values depending on which database is used, embedded or server.
    # @abstract
    def _query(*params)
      raise 'not implemented'
    end

    class << self
      # Creates a new session
      # @param db_type the type of database, e.g. :embedded_db, or :server_db
      def open(db_type, *params)
        register(create_session(db_type, params))
      end

      def open_named(db_type, name, default = nil, *params)
        register(create_session(db_type, params), name, default)
      end

      def create_session(db_type, params)
        unless (@@factories[db_type])
          raise "Can't connect to database '#{db_type}', available #{@@factories.keys.join(',')}"
        end
        @@factories[db_type].call(*params)
      end

      def current
        @@current_session
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
