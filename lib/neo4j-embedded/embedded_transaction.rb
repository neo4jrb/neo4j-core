module Neo4j
  module Embedded
    class EmbeddedTransaction < Neo4j::Transaction::Base
      attr_reader :root_tx

      def initialize(session)
        super
        @root_tx = @session.begin_tx
      end

      def acquire_read_lock(entity)
        @root_tx.acquire_read_lock(entity)
      end

      def acquire_write_lock(entity)
        @root_tx.acquire_write_lock(entity)
      end

      def delete
        @root_tx.failure
        @root_tx.close
      end

      def commit
        @root_tx.success
        @root_tx.close
      end
    end
  end
end
