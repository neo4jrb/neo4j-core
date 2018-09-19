# frozen_string_literal: true

require 'neo4j/core/cypher_session/transactions'

module Neo4j
  module Core
    class CypherSession
      module Transactions
        class BoltRouting < Base
          attr_accessor :connection

          def initialize(*args)
            @connection = nil

            super

            tx_query('BEGIN') if root?
          end

          def commit
            tx_query('COMMIT') if root?
            @connection = nil
          end

          def delete
            tx_query('ROLLBACK')
            @connection = nil
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
