module Neo4j
  class Transaction
    def self.new(current = Session.current)
      current.begin_tx
    end


    class << self

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
          tx.finish unless tx.nil?
        end
        ret
      end

      def current
        Thread.current[:neo4j_curr_tx]
      end

      def unregister(tx)
        Thread.current[:neo4j_curr_tx] = nil if tx == Thread.current[:neo4j_curr_tx]
      end

      def register(tx)
        # we don't support running more then one transaction per thread
        raise "Already running a transaction" if current
        Thread.current[:neo4j_curr_tx] = tx
      end

      def unregister_current
        Thread.current[:neo4j_curr_tx] = nil
      end
    end

  end
end
