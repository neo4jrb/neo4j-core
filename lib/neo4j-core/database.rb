module Neo4j
  module Core
    # Wraps both Java Neo4j GraphDatabaseService and Lucene.
    # You can access the raw java neo4j and lucene db's with the <tt>graph</tt> and <tt>lucene</tt>
    # properties.
    #
    # This class is also responsible for checking if there is already a running neo4j database.
    # If one tries to start an already started database then a read only instance to neo4j will be used.
    # Many of the methods here are delegated from the Neo4j module
    #
    # @private
    class Database
      include org.neo4j.kernel.GraphDatabaseAPI

      # The Java graph database
      # @see http://components.neo4j.org/neo4j/1.6.1/apidocs/org/neo4j/graphdb/GraphDatabaseService.html
      # @return [Java::OrgNeo4jGraphdb::GraphDatabaseService]
      attr_reader :graph

      # The lucene index manager
      # @see http://components.neo4j.org/neo4j/1.6.1/apidocs/org/neo4j/graphdb/index/IndexManager.html
      # @return [Java::OrgNeo4jGraphdbIndex::IndexManager]
      attr_reader :lucene

      # @return [Neo4j::EventHandler] the event handler listining to commit events
      attr_reader :event_handler

      # @return [String] The location of the database
      attr_reader :storage_path

      alias_method :index, :lucene # needed by cypher

      def initialize()
        @event_handler = EventHandler.new
      end

      def self.default_embedded_db
        @default_embedded_db || Java::OrgNeo4jKernel::EmbeddedGraphDatabase
      end

      def self.default_embedded_db=(db)
        @default_embedded_db = db
      end

      def self.ha_enabled?
        Neo4j::Config['ha.db']
      end


      # Private start method, use Neo4j.start instead
      # @see Neo4j#start
      def start
        return if running?
        @running = true
        @storage_path = Config.storage_path

        begin
          if self.class.locked?
            start_readonly_graph_db
          elsif self.class.ha_enabled?
            start_ha_graph_db
            Neo4j.migrate! if Neo4j.respond_to?(:migrate!)
          else
            start_local_graph_db
            Neo4j.migrate! if Neo4j.respond_to?(:migrate!)
          end
        rescue
          @running = false
          raise
        end

        at_exit { shutdown }
      end


      # true if the database has started
      def running?
        @running
      end

      # Returns true if the neo4j db was started in read only mode.
      # This can occur if the database was locked (it was already one instance running).
      # @see Neo4j#read_only?
      def read_only?
        @graph.java_class == Java::OrgNeo4jKernel::EmbeddedReadOnlyGraphDatabase
      end

      # check if the database is locked. A neo4j database is locked when the database is running.
      def self.locked?
        lock_file = File.join(Neo4j.config.storage_path, 'neostore')
        return false unless File.exist?(lock_file)
        rfile = java.io.RandomAccessFile.new(lock_file, 'rw')
        begin
          lock = rfile.getChannel.tryLock
          lock.release if lock
          return lock == nil # we got the lock, so that means it is not locked.
        rescue Exception => e
          return false
        end
      end

      # Internal method, see Neo4j#shutdown
      def shutdown
        if @running
          @graph.unregister_transaction_event_handler(@event_handler) unless read_only?
          @event_handler.neo4j_shutdown(self)
          @graph.shutdown
          @graph = nil
          @lucene = nil
          @running = false
          @neo4j_manager = nil
          if self.class.ha_enabled?
            Neo4j.logger.info "Neo4j (HA mode) has been shutdown, machine id: #{Neo4j.config['ha.server_id']} at #{Neo4j.config['ha.server']} db #{@storage_path}"
          else
            Neo4j.logger.info "Neo4j has been shutdown using storage_path: #{@storage_path}"
          end
        end
      end


      # @see Neo4j.management
      def management(jmx_clazz)
        @neo4j_manager ||= Java::OrgNeo4jManagement::Neo4jManager.new(@graph.get_management_bean(org.neo4j.jmx.Kernel.java_class))
        @neo4j_manager.getBean(jmx_clazz.java_class)
      end

      # private method, used from Neo4j::Transaction.new
      def begin_tx
        @graph.begin_tx
      end

      # @see Neo4j.all_nodes
      def each_node
        iter = @graph.all_nodes.iterator
        while (iter.hasNext)
          yield iter.next.wrapper
        end
      end

      # @see Neo4j._all_nodes
      def _each_node
        iter = @graph.all_nodes.iterator
        while (iter.hasNext)
          yield iter.next
        end
      end

      # @private
      def start_external_db(external_graph_db)
        begin
          @running = true
          @graph = external_graph_db
          @graph.register_transaction_event_handler(@event_handler)
          @lucene = @graph.index
          @event_handler.neo4j_started(self)
          Neo4j.logger.info("Started with external db")
        rescue
          @running = false
          raise
        end
      end

      private

      def start_readonly_graph_db
        Neo4j.logger.info "Starting Neo4j in readonly mode since the #{@storage_path} is locked"
        @graph = Java::OrgNeo4jKernel::EmbeddedReadOnlyGraphDatabase.new(@storage_path, Config.to_java_map)
        @lucene = @graph.index
      end

      def start_local_graph_db
        Neo4j.logger.info "Starting local Neo4j using db #{@storage_path} using #{self.class.default_embedded_db}"
        @graph = self.class.default_embedded_db.new(@storage_path, Config.to_java_map)
        @graph.register_transaction_event_handler(@event_handler)
        @lucene = @graph.index
        @event_handler.neo4j_started(self)
      end


      def start_ha_graph_db
        Neo4j.logger.info "starting Neo4j in HA mode, machine id: #{Neo4j.config['ha.server_id']} at #{Neo4j.config['ha.server']} db #{@storage_path}"
        # Modify the public base classes for the HA Node and Relationships
        # (instead of private Java::OrgNeo4jKernel::HighlyAvailableGraphDatabase::LookupNode)
        @graph = Java::OrgNeo4jKernel::HighlyAvailableGraphDatabase.new(@storage_path, Neo4j.config.to_java_map)
        @graph.register_transaction_event_handler(@event_handler)
        @lucene = @graph.index
        @event_handler.neo4j_started(self)
      end

      # Implementation of org.neo4j.kernel.GraphDatabaseAPI
      # For some strange reason Cypher seems to need those methods

      # needed by cypher
      def getNodeById(id)
        Neo4j::Node.load(id)
      end

      # needed by cypher
      def getRelationshipById(id)
        Neo4j::Relationship.load(id)
      end

      # needed by cypher
      def getNodeManager
        @graph.getNodeManager
      end

    end
  end
end
