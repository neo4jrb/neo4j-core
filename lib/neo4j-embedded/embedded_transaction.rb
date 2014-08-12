module Neo4j::Embedded
  class EmbeddedTransaction

    def initialize(root_tx)
      @root_tx = root_tx
      @pushed_nested = 0
      Neo4j::Transaction.register(self)
    end

    def success
      # this is need in the Java API
    end

    def failure
      @failure = true
    end

    def failure?
      !!@failure
    end

    def push_nested!
      @pushed_nested += 1
    end

    def pop_nested!
      @pushed_nested -= 1
    end

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

    alias_method :finish, :close

    def _delete_tx
      @root_tx.failure
      @root_tx.close
    end

    def _commit_tx
      @root_tx.success
      @root_tx.close
    end

  end
end