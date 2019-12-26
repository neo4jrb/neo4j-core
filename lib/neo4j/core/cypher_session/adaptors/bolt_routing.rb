require_relative "./bolt"

# TODO: Work with `Query` objects?
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class BoltRouting < Bolt
          include Adaptors::HasUri
          include Adaptors::Schema
          default_url('bolt+routing://neo4:neo4j@localhost:7687')
          validate_uri do |uri|
            uri.scheme == 'bolt+routing'
          end

          def queries(session, options = {}, &block)
            query_builder = QueryBuilder.new

            query_builder.instance_eval(&block)

            # Determine read or write query
            write_queries = query_builder.queries.count { |q| /(CREATE|DELETE|DETACH|DROP|SET|REMOVE|FOREACH|MERGE|CALL)/.match?(q.cypher) }
            access_mode = write_queries.zero? ? :read : :write

            new_or_current_transaction(session, access_mode, options[:transaction]) do |tx|
              query_set(tx, query_builder.queries, {commit: !options[:transaction]}.merge(options))
            end
          end

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/bolt_routing'
            Neo4j::Core::CypherSession::Transactions::BoltRouting
          end

          private

          # Override to differentiate between write and read transactions
          def new_or_current_transaction(session, access_mode, tx, &block)
            if tx && tx.access_mode == access_mode
              yield(tx)
            else
              transaction(session, access_mode, &block)
            end
          end

          # Override to differentiate between write and read transactions
          def transaction(session, access_mode = :write)
            if !block_given?
              tx = self.class.transaction_class.new(session)
              tx.access_mode = access_mode
              tx.begin
              return tx
            end

            begin
              tx = transaction(session, access_mode)
              yield tx
            rescue => e
              tx.mark_failed if tx
              raise e
            ensure
              tx.close if tx
            end
          end

          def build_response(queries, wrap_level)
            catch(:cypher_bolt_failure) do
              Responses::Bolt.new(queries, method(:flush_messages), wrap_level: wrap_level).results
            end.tap do |error_data|
              handle_failure!(error_data) if !error_data.is_a?(Array)
            end
          end

          # Represents messages sent to or received from the server
          class Message < Neo4j::Core::CypherSession::Adaptors::Bolt::Message; end

          # Represents a set of messages to send to the server
          class Job < Neo4j::Core::CypherSession::Adaptors::Bolt::Job; end
        end
      end
    end
  end
end
