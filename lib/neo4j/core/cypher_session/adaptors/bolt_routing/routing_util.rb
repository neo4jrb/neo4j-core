# frozen_string_literal: true

module Neo4j
  module Core
    module BoltRouting
      class RoutingUtil
        CALL_GET_ROUTING_TABLE = 'CALL dbms.cluster.routing.getRoutingTable({context})'
        CALL_GET_SERVERS = 'CALL dbms.cluster.routing.getServers'
        PROCEDURE_NOT_FOUND_CODE = 'Neo.ClientError.Procedure.ProcedureNotFound'

        def initialize(routing_context)
          @routing_context = routing_context
        end

        def call_routing_procedure(session, router_address)
          call_available_routing_procedure(session) do |result|
            result
          end
        rescue => e
          raise Neo4j::Core::CypherSession::CypherError::ConnectionFailedError, "Server at #{ router_address } cannot perform routing. Make sure you are connecting to a causal cluster." if e.code == PROCEDURE_NOT_FOUND_CODE
        end

        def parse_servers(record, router_address)
          servers = record.properties[:servers]

          readers = []
          routers = []
          writers = []

          servers.each do |server|
            role = server[:role]
            addresses = server[:addresses]

            if role == 'ROUTE'
              routers += addresses.to_a
            elsif role == 'WRITE'
              writers += addresses.to_a
            elsif role == 'READ'
              readers += addresses.to_a
            else
              raise ArgumentError, "Unknown server role: `#{ role }`."
            end
          end

          {
            readers: readers,
            routers: routers,
            writers: writers,
          }
        rescue => e
          raise Neo4j::Core::CypherSession::CypherError::ConnectionFailedError, "Unable to parse servers entry from router #{ router_address } with record #{ record } (#{ e.message })."
        end

        def parse_ttl(record, router_address)
          expires = record.properties[:ttl] * 1000 + Time.now.to_i
        rescue => e
          raise Neo4j::Core::CypherSession::CypherError::ConnectionFailedError, "Unable to parse TTL entry from router #{ router_address } with record #{ record } (#{ e.message })."
        end

        private

        def call_available_routing_procedure(session)
          Neo4j::Transaction.run(session) do |tx|
            if session.adaptor.server.version <=> Gem::Version.new('3.2.0') >= 0
              tx.query(CALL_GET_ROUTING_TABLE, { context: @routing_context })
            else
              tx.query(CALL_GET_SERVERS)
            end
          end
        end
      end
    end
  end
end
