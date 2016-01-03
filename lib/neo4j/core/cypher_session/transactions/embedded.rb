require 'neo4j/core/cypher_session/transactions'

module Neo4j
  module Core
    class CypherSession
      module Transactions
        class Embedded < Base
          def initialize(*args)
            super
            @java_tx = adaptor.graph_db.begin_tx
          end

          def close
            @java_tx.success if !@failure
            @java_tx.close
          end

          def mark_failed
            @failure = true
            @java_tx.failure
          end

          private

          # Because we're inheriting from the old Transaction class
          # but the new adaptors work much like the old sessions
          def adaptor
            @session
          end
        end
      end
    end
  end
end
