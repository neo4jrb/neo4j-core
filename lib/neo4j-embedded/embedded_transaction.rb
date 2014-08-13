module Neo4j::Embedded
  class EmbeddedTransaction

    include Neo4j::Transaction::Instance

    def initialize(root_tx)
      @root_tx = root_tx
      register_instance
    end

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