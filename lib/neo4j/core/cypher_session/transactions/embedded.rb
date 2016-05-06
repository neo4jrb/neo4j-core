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

          def commit
            @java_tx.success if !@failure
            @java_tx.close
          end

          def delete
            @failure = true
            @java_tx.failure
          end
        end
      end
    end
  end
end
