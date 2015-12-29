module Neo4j
  module Transaction
    extend self

    module Instance
      # @private
      def register_instance
        Neo4j::Transaction.register(self)
      end

      # Marks this transaction as failed, which means that it will unconditionally be rolled back when close() is called. Aliased for legacy purposes.
      def mark_failed
        @failure = true
      end
      alias_method :failure, :mark_failed

      # If it has been marked as failed. Aliased for legacy purposes.
      def failed?
        !!@failure
      end
      alias_method :failure?, :failed?

      def autoclosed!
        @autoclosed = true if transient_failures_autoclose?
      end

      def transient_failures_autoclose?
        Neo4j::Session.current.version >= '2.2.6'
      end

      def autoclosed?
        !!@autoclosed
      end

      def mark_expired
        @expired = true
      end

      def expired?
        !!@expired
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
        fail "Can't commit transaction, already committed" if @pushed_nested < -1
        Neo4j::Transaction.unregister(self)
        post_close!
      end

      private

      def post_close!
        return if autoclosed?
        if failed?
          delete
        else
          commit
        end
      end
    end

    # @return [Neo4j::Transaction::Instance]
    def new(session = Session.current!)
      if current
        current.push_nested!
      else
        new_transaction = if session.is_a?(::Neo4j::Session)
                            session.class.transaction_class.new(session)
                          else
                            Neo4j::Core::CypherSession::Transaction.new(session)
                          end

        register(new_transaction)
      end

      current
    end

    # Runs the given block in a new transaction.
    # @param [Boolean] run_in_tx if true a new transaction will not be created, instead if will simply yield to the given block
    # @@yield [Neo4j::Transaction::Instance]
    def run(run_in_tx = true, session = Session.current!)
      fail ArgumentError, 'Expected a block to run in Transaction.run' unless block_given?

      return yield(nil) unless run_in_tx

      tx = Neo4j::Transaction.new(session)
      yield tx
    rescue Exception => e # rubocop:disable Lint/RescueException
      print_exception_cause(e)
      tx.mark_failed unless tx.nil?
      raise
    ensure
      tx.close unless tx.nil?
    end

    # @return [Neo4j::Transaction]
    def current
      Thread.current[:neo4j_curr_tx]
    end

    # @private
    def print_exception_cause(exception)
      return if !exception.respond_to?(:cause) || !exception.cause.respond_to?(:print_stack_trace)

      puts "Java Exception in a transaction, cause: #{exception.cause}"
      exception.cause.print_stack_trace
    end

    # @private
    def unregister(tx)
      Thread.current[:neo4j_curr_tx] = nil if tx == Thread.current[:neo4j_curr_tx]
    end

    # @private
    def register(tx)
      # we don't support running more then one transaction per thread
      fail 'Already running a transaction' if current
      Thread.current[:neo4j_curr_tx] = tx
    end

    # @private
    def unregister_current
      Thread.current[:neo4j_curr_tx] = nil
    end
  end
end
