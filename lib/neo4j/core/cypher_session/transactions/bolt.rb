require 'neo4j/core/cypher_session/transactions'

module Neo4j
  module Core
    class CypherSession
      module Transactions
        class Bolt < Base
          def initialize(*args)
            super

            tx_query('BEGIN') if root?
          end

          def commit
            tx_query('COMMIT') if root?
          end

          def delete
            tx_query('ROLLBACK')
          end

          def started?
            true
          end

          private

          def tx_query(cypher)
            query = Adaptors::Base::Query.new(cypher, {}, cypher)
            adaptor.send(:query_set, self, [query], skip_instrumentation: true)
          end
        end
      end
    end
  end
end
