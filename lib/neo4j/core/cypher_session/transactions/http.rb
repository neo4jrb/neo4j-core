require 'neo4j/core/cypher_session/transactions'

module Neo4j
  module Core
    class CypherSession
      module Transactions
        class HTTP < Base
          # Should perhaps have transaction adaptors only define #close
          # commit/delete are, I think, an implementation detail

          def commit
            adaptor.requestor.request(:post, query_path(true)) if started?
          end

          def delete
            adaptor.requestor.request(:delete, query_path) if started?
          end

          def query_path(commit = false)
            if id
              "/db/data/transaction/#{id}"
            else
              '/db/data/transaction'
            end.tap do |path|
              path << '/commit' if commit
            end
          end

          # Takes the transaction URL from Neo4j and parses out the ID
          def apply_id_from_url!(url)
            root.instance_variable_set('@id', url.match(%r{/(\d+)/?$})[1].to_i) if url
            # @id = url.match(%r{/(\d+)/?$})[1].to_i if url
          end

          def started?
            !!id
          end

          def id
            root.instance_variable_get('@id')
          end

          private

          def connection
            adaptor.connection
          end
        end
      end
    end
  end
end
