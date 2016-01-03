module Neo4j
  module Core
    class CypherSession
      module Transactions
        class Base < Neo4j::Transaction::Base
          # Will perhaps be a bit odd as we will pass in the adaptor
          # as the @session for these new transactions
          def query(query, parameters = {}, options = {})
            adaptor.query(query, parameters, {transaction: self, commit: false}.merge(options))
          end

          def queries(options = {}, &block)
            adaptor.queries({transaction: self, commit: false}.merge(options), &block)
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
