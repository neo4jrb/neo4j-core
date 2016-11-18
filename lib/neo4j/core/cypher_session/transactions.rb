module Neo4j
  module Core
    class CypherSession
      module Transactions
        class Base < Neo4j::Transaction::Base
          def query(*args)
            options = if args[0].is_a?(::Neo4j::Core::Query)
                        args[1] ||= {}
                      else
                        args[1] ||= {}
                        args[2] ||= {}
                      end
            options[:transaction] ||= self

            adapter.query(@session, *args)
          end

          def queries(options = {}, &block)
            adapter.queries(@session, {transaction: self}.merge(options), &block)
          end

          private

          # Because we're inheriting from the old Transaction class
          # but the new adapters work much like the old sessions
          def adapter
            @session.adapter
          end
        end
      end
    end
  end
end
