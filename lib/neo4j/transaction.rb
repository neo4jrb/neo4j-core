module Neo4j
  module Transaction

    extend self

    module Instance
      # @private
      def register_instance
        @pushed_nested = 0
        Neo4j::Transaction.register(self)
      end

      # Marks this transaction as failed, which means that it will unconditionally be rolled back when close() is called.
      def failure
        @failure = true
      end

      # If it has been marked as failed
      def failure?
        !!@failure
      end

      # @private
      def push_nested!
        @pushed_nested += 1
      end

      # @private
      def pop_nested!
        @pushed_nested -= 1
      end

      # Only for the embedded neo4j !
      # Acquires a read lock for entity for this transaction.
      # See neo4j java docs.
      # @param [Neo4j::Node,Neo4j::Relationship] entity
      # @return [Java::OrgNeo4jKernelImplCoreapi::PropertyContainerLocker]
      def acquire_read_lock(entity)
      end

      # Only for the embedded neo4j !
      # Acquires a write lock for entity for this transaction.
      # See neo4j java docs.
      # @param [Neo4j::Node,Neo4j::Relationship] entity
      # @return [Java::OrgNeo4jKernelImplCoreapi::PropertyContainerLocker]
      def acquire_write_lock(entity)
      end

      # Commits or marks this transaction for rollback, depending on whether failure() has been previously invoked.
      def close
        pop_nested!
        return if @pushed_nested >= 0
        raise "Can't commit transaction, already committed" if (@pushed_nested < -1)
        Neo4j::Transaction.unregister(self)
        if failure?
          _delete_tx
        else
          _commit_tx
        end
      end

    end



    # @return [Neo4j::Transaction::Instance]
    def new(current = Session.current!)
      current.begin_tx
    end

    # Runs the given block in a new transaction.
    # @param [Boolean] run_in_tx if true a new transaction will not be created, instead if will simply yield to the given block
    # @@yield [Neo4j::Transaction::Instance]
    def run(run_in_tx=true)
      raise ArgumentError.new("Expected a block to run in Transaction.run") unless block_given?

      return yield(nil) unless run_in_tx

      begin
        tx = Neo4j::Transaction.new
        ret = yield tx
      rescue Exception => e
        if e.respond_to?(:cause) && e.cause
          puts "Java Exception in a transaction, cause: #{e.cause}"
          e.cause.print_stack_trace
        end
        tx.failure unless tx.nil?
        raise
      ensure
        tx.close unless tx.nil?
      end
      ret
    end

    # @return [Neo4j::Transaction]
    def current
      Thread.current[:neo4j_curr_tx]
    end

    # @private
    def unregister(tx)
      Thread.current[:neo4j_curr_tx] = nil if tx == Thread.current[:neo4j_curr_tx]
    end

    # @private
    def register(tx)
      # we don't support running more then one transaction per thread
      raise "Already running a transaction" if current
      Thread.current[:neo4j_curr_tx] = tx
    end

    # @private
    def unregister_current
      Thread.current[:neo4j_curr_tx] = nil
    end

  end
end
