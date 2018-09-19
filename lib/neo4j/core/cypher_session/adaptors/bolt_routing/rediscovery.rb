# frozen_string_literal: true

require 'neo4j/core/cypher_session/adaptors/bolt_routing/routing_table'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/routing_util'

module Neo4j
  module Core
    module BoltRouting
      class Rediscovery
        def self.assert_not_empty(server_addresses, servers_name, router_address)
          raise ArgumentError, "Received no #{ servers_name } from router #{ router_address }." if server_addresses.empty?
        end

        def initialize(routing_context)
          @routing_context = routing_context
        end

        def look_up_routing_table_on_router(session, router_address)
          records = routing_util.call_routing_procedure(session, router_address)

          return unless records
          raise ArgumentError, "Illegal response from router #{ router_address }. Received #{ records.hashes.size } records but only expected one." unless records.hashes.size == 1

          record = records.hashes.first

          expiration_time = routing_util.parse_ttl(record, router_address)
          servers = routing_util.parse_servers(record, router_address)

          Rediscovery.assert_not_empty(servers[:routers], 'routers', router_address)
          Rediscovery.assert_not_empty(servers[:readers], 'readers', router_address)

          RoutingTable.new(servers[:routers], servers[:readers], servers[:writers], expiration_time)
        end

        private

        def routing_util
          @routing_util ||= RoutingUtil.new(@routing_context)
        end
      end
    end
  end
end
