# -*- coding: utf-8 -*-

# = Neo4j
#
# The Neo4j modules is used to interact with an Neo4j Database instance.
# You can for example start and stop an instance and list all the nodes that exist in the database.
#
# @example
#   require 'neo4j'
#   Neo4j::Transaction.run { Neo4j.ref_node.outgoing(:friends) << Neo4j::Node.new(:name => 'andreas')}
#   Neo4j.ref_node.node(:outgoing, :friends)[:name] #=> 'andreas'
#   Neo4j.query(Neo4j.ref_node){|ref| ref > ':friends' > :x; :x}
#
# ==== Notice - Starting and Stopping Neo4j
# You don't normally need to start the Neo4j database since it will be automatically started when needed.
# Before the database is started you should configure where the database is stored, see {Neo4j::Config]}.
#
#
module Neo4j

  # @return [String] The version of the Neo4j jar files
  NEO_VERSION = Neo4j::Community::VERSION

  class << self

    # Start Neo4j using the default database.
    # This is usually not required since the database will be started automatically when it is used.
    # If the global variable $NEO4J_SERVER is defined then it will use that as the Java Graph DB. This can
    # be used if you want to embed neo4j.rb and already got an instance of the Java Neo4j Database service.
    #
    # @param [String] config_file (optionally) if this is nil or not given use the Neo4j::Config, otherwise setup the Neo4j::Config file using the provided YAML configuration file.
    # @param [Java::OrgNeo4jKernel::EmbeddedGraphDatabase] external_db (optionally) use this Java Neo4j instead of creating a new neo4j database service.
    def start(config_file=nil, external_db = $NEO4J_SERVER)
        return if @db && @db.running?

        Neo4j.config.default_file = config_file if config_file
        if external_db
          @db ||= Neo4j::Core::Database.new
          self.db.start_external_db(external_db)
        else
          db.start
        end
    end


    # Sets which Neo4j::Database instance to use. It wraps both the Neo4j Database and Lucene Database.
    # @param [Neo4j::Database] my_db - the database instance to use
    def db=(my_db)
      @db = my_db
    end

    # Returns the database holding references to both the Neo4j Graph Database and the Lucene Database.
    # Creates a new one if it does not exist, but does not start it.
    #
    # @return [Neo4j::Database] the created or existing database
    def db
      @db ||= Neo4j::Core::Database.new
    end

    # Checks read only mode of the database. Only one process can have write access to the database.
    # It will always return false if the database is not started yet.
    # @return [true, false] if the database has started up in read only mode
    def read_only?
      !!(@db && @db.graph && @db.read_only?)
    end

    # Returns a started db instance. Starts it's not running.
    # if $NEO4J_SERVER is defined then use that Java Neo4j Database service instead of creating a new one.
    # @return [Neo4j::Database] a started database
    def started_db
      start unless db.running?
      db
    end

    # If the database is not running it returns Neo4j::Config.storage_path otherwise it asks the database
    # @return [String] the current storage path of the database
    def storage_path
      return Neo4j::Config.storage_path unless db.running?
      db.storage_path
    end

    # Same as typing; Neo4j::Config
    # @return [Neo4j::Config] the Neo4j::Config class
    def config
      Neo4j::Config
    end

    # Executes a Cypher Query
    # Check the neo4j 
    # Returns an enumerable of hash values.
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
    # @example With an string
    #  q = Neo4j._query("START n=node(42) RETURN n")
    #  q.first(:n) #=> the @node
    #  q.columns.first => :n
    #
    # @see Cypher
    # @see http://docs.neo4j.org/chunked/milestone/cypher-query-lang.html The Cypher Query Language Documentation
    # @note Returns a read-once only forward iterable.
    # @param params parameter for the query_dsl block
    # @return [Neo4j::Cypher::ResultWrapper] a forward read once only Enumerable, containing hash values.
    def query(*params, &query_dsl)
      q = Neo4j::Cypher.query(*params, &query_dsl).to_s
      _query(q)
    end

    # Performs a cypher query with given string
    # @param [String] q the cypher query as a String
    # @return (see #query)
    def _query(q, params={})
      engine = Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(db)
      result = engine.execute(q, params)
      Neo4j::Cypher::ResultWrapper.new(result)
    end


    # Returns the logger used by neo4j.
    # If not specified (with Neo4j.logger=) it will use the standard Ruby logger.
    # You can change standard logger threshold by configuration :logger_level.
    #
    # You can also specify which logger class should take care of logging with the
    # :logger configuration.
    #
    # @example
    #
    #  Neo4j::Config[:logger] = Logger.new(STDOUT)
    #  Neo4j::Config[:logger_level] = Logger::ERROR
    #
    # @see #logger=
    def logger
      @logger ||= Neo4j::Config[:logger] || default_logger
    end

    # Sets which logger should be used.
    # If this this is not called then the standard Ruby logger will be used.
    # @see #logger
    def logger=(logger)
      @logger = logger
    end

    # @return the default Ruby logger
    def default_logger #:nodoc:
      require 'logger'
      logger = Logger.new(STDOUT)
      logger.sev_threshold = Neo4j::Config[:logger_level] || Logger::INFO
      logger
    end


    # Returns an unstarted db instance
    #
    # This is typically used for configuring the database, which must sometimes
    # be done before the database is started
    # if the database was already started an exception will be raised
    # @return [Neo4j::Database] an not started database
    def unstarted_db
      @db ||= Neo4j::Core::Database.new
      raise "database was already started" if @db.running?
      @db
    end

    # @return [true,false] if the database is running
    def running?
      !!(@db && @db.running?)
    end


    # Stops this database
    # There are Ruby hooks that will do this automatically for you.
    def shutdown(this_db = @db)
      this_db.shutdown if this_db
    end


    # @return the default reference node, which is a "starting point" in the node space.
    def default_ref_node(this_db = self.started_db)
      this_db.graph.reference_node
    end

    # Usually, a client attaches relationships to this node that leads into various parts of the node space.
    # ®return the reference node, which is a "starting point" in the node space.
    # @note In case the ref_node has been assigned via the threadlocal_ref_node method,
    #       then that node will be returned instead.
    def ref_node(this_db = self.started_db)
      return Thread.current[:local_ref_node] if Thread.current[:local_ref_node]
      default_ref_node(this_db)
    end

    # Changes the reference node on a threadlocal basis.
    # This can be used to achieve multitenancy. All new entities will be attached to the new ref_node,
    # which effectively partitions the graph, and hence scopes traversals.
    def threadlocal_ref_node=(reference_node)
      Thread.current[:local_ref_node] = reference_node.nil? ? nil : reference_node._java_node
    end

    # Returns a Management JMX Bean.
    #
    # Notice that this information is also provided by the jconsole Java tool, check http://wiki.neo4j.org/content/Monitoring_and_Deployment
    # and http://docs.neo4j.org/chunked/milestone/operations-monitoring.html.
    # Some of these management features are only available when using the neo4j-advanced and neo4j-enterprise gems.
    #
    # By default it returns the Primitivies JMX Bean that can be used to find number of nodes in use.
    #
    # @example Example Neo4j Primititives
    #
    #   Neo4j.management.get_number_of_node_ids_in_use
    #   Neo4j.management.getNumberOfPropertyIdsInUse
    #   Neo4j.management.getNumberOfRelationshipIdsInUse
    #   Neo4j.management.get_number_of_relationship_type_ids_in_use
    #
    # Notice you must require the neo4j-advanced gem for these stats.
    #
    # @example Example Neo4j HA Cluster Info
    #
    #   Neo4j.management(org.neo4j.management.HighAvailability).isMaster
    #
    # @param jmx_clazz the JMX class http://api.neo4j.org/current/org/neo4j/management/package-summary.html
    # @param this_db default currently running instance or a newly started neo4j db instance
    # @see for the jmx_clazz p
    # @node this
    def management(jmx_clazz = Java::OrgNeo4jJmx::Primitives, this_db = self.started_db)
      this_db.management(jmx_clazz)
    end

    # Only available using the neo4j-enterprise gem.
    # @return [Boolean] true if the Neo4j database is the HA master
    def ha_master?
      db.graph && db.graph.isMaster()
    end

    # @return [Enumerable] all nodes in the database
    def all_nodes(this_db = self.started_db)
      Enumerator.new(this_db, :each_node)
    end

    # @return [Enumerable] all nodes in the database but not wrapped in ruby classes.
    def _all_nodes(this_db = self.started_db)
      Enumerator.new(this_db, :_each_node)
    end

    # @return [Neo4j::Core::EventHandler] the event handler
    def event_handler(this_db = db)
      this_db.event_handler
    end

  end
end
