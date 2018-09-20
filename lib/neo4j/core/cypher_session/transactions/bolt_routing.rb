# frozen_string_literal: true

require 'neo4j/core/cypher_session/transactions'

module Neo4j
  module Core
    class CypherSession
      module Transactions
        class BoltRouting < Base
          attr_accessor :access_mode, :connection

          def initialize(*args)
            @access_mode = :write
            @connection = nil

            super

            tx_query('BEGIN') if root?
          end

          def commit
            tx_query('COMMIT') if root?
            @connection.release
            @connection = nil
          end

          def delete
            tx_query('ROLLBACK')
            @connection.release
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
