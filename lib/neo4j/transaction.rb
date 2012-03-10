module Neo4j
  #
  # All modifying operations that work with the node space must be wrapped in a transaction. Transactions are thread confined.
  # Neo4j does not implement true nested transaction, instead it uses flat nested transactions
  #
  # @see http://docs.neo4j.org/chunked/milestone/transactions.html
  class Transaction

    # Acquires a write lock for entity for this transaction. The lock (returned from this method) can be released manually, but if not it's released automatically when the transaction finishes.
    # There is no implementation for this here because it's an java method
    #
    # @param [Neo4j::Relationship, Neo4j::Node] java_entity the entity to acquire a lock for. If another transaction currently holds a write lock to that entity this call will wait until it's released.
    # @return [Java::OrgNeo4jGraphdb::Lock] a Lock which optionally can be used to release this lock earlier than when the transaction finishes. If not released (with Lock.release() it's going to be released with the transaction finishes.
    # @see http://api.neo4j.org/current/org/neo4j/graphdb/Transaction.html#acquireWriteLock(Java::OrgNeo4jGraphdb::PropertyContainer)
    # @see http://api.neo4j.org/current/org/neo4j/graphdb/Lock.html
    def acquire_write_lock(java_entity)
    end

    # Acquires a read lock for entity for this transaction. The lock (returned from this method) can be released manually, but if not it's released automatically when the transaction finishes.
    # There is no implementation for this here because it's an java method
    # @param [Neo4j::Relationship, Neo4j::Node] java_entity the entity to acquire a lock for. If another transaction currently hold a write lock to that entity this call will wait until it's released.
    # @return [Java::OrgNeo4jGraphdb::Lock]  a Lock which optionally can be used to release this lock earlier than when the transaction finishes. If not released (with Lock.release() it's going to be released with the transaction finishes.
    # @see http://api.neo4j.org/current/org/neo4j/graphdb/Transaction.html#acquireReadLock(Java::OrgNeo4jGraphdb::PropertyContainer)
    # @see http://api.neo4j.org/current/org/neo4j/graphdb/Lock.html
    def acquire_read_lock(java_entity)
    end

    # Starts a new Neo4j Transaction
    # @return [Java::OrgNeo4jGraphdb::Transaction] a Java Neo4j Transaction object
    # @see http://api.neo4j.org/current/org/neo4j/graphdb/Transaction.html
    #
    # @example
    #  tx = Neo4j::Transaction.new
    #  # modify something
    #  tx.success
    #  tx.finish
    def self.new(instance = Neo4j.started_db)
      instance.begin_tx
    end

    # Runs a block in a Neo4j transaction
    #
    # Many operations on neo requires an transaction. You will get much better performance if
    # one transaction is wrapped around several neo operation instead of running one transaction per
    # neo operation.
    # If one transaction is already running then a 'placebo' transaction will be created.
    # Performing a finish on a placebo transaction will not finish the 'real' transaction.
    #
    # If an exception occurs inside the block the transaction will rollback automatically.
    #
    # @example
    #
    #  Neo4j::Transaction.run { node = PersonNode.new }
    #
    # @example access to the transaction and rollback
    #
    #   Neo4j::Transaction.run do |t|
    #     # something failed
    #     t.failure # will cause a rollback
    #   end
    #
    # @yield the block which should be run under one transaction
    # @yieldparam [Neo4j::Transaction]
    # @return The value of the evaluated provided block
    #
    def self.run
      raise ArgumentError.new("Expected a block to run in Transaction.run") unless block_given?

      begin
        tx = Neo4j::Transaction.new
        ret = yield tx
        tx.success
      rescue Exception => e
        if Neo4j::Config[:debug_java] && e.respond_to?(:cause)
          puts "Java Exception in a transaction, cause: #{e.cause}"
          e.cause.print_stack_trace
        end
        tx.failure unless tx.nil?
        raise
      ensure
        tx.finish unless tx.nil?
      end
      ret
    end
  end
end