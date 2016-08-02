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
            return if !@java_tx

            @java_tx.success
            @java_tx.close
          rescue Java::OrgNeo4jGraphdb::TransactionFailureException => e
            raise CypherError, e.message
          end

          def delete
            return if !@java_tx

            @java_tx.failure
            @java_tx.close
          end
        end
      end
    end
  end
end
