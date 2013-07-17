module Neo4j
  class Transaction
    def self.new(instance = Database.instance)
      instance.begin_tx
    end

    def self.run(run_in_tx=true)
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
  end

end
