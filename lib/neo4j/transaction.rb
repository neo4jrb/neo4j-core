module Neo4j
  class Transaction

    # @!method close
    #   Commits or marks this transaction for rollback, depending on whether success() or failure() has been previously invoked


    # @!method success
    #  Marks this transaction as successful, which means that it will be committed upon invocation of close() unless failure() has or will be invoked before then.


    # @!method failure
    #  Marks this transaction as failed, which means that it will unconditionally be rolled back when close() is called.

    def self.new(current = Session.current)
      current.begin_tx
    end


    class << self

      # Runs the given block in a new transaction.
      # @param [Boolean] run_in_tx if true a new transaction will not be created, instead if will simply yield to the given block
      def run(run_in_tx=true)
        raise ArgumentError.new("Expected a block to run in Transaction.run") unless block_given?

        return yield(nil) unless run_in_tx

        begin
          tx = Neo4j::Transaction.new
          ret = yield tx
          tx.success
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
end
