# frozen_string_literal: true

require 'neo4j/core/cypher_session/adaptors/bolt_routing/rediscovery'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/routing_table'

module Neo4j
  module Core
    module BoltRouting
      class LoadBalancer
        def initialize(host_port, routing_context, connection_pool, load_balancing_strategy, host_name_resolver)
          @seed_router = host_port
          @routing_context = routing_context
          @connection_pool = connection_pool
          @load_balancing_strategy = load_balancing_strategy
          @host_name_resolver = host_name_resolver
          @use_seed_router = false
        end

        def acquire_connection(access_mode)
        end

        private

        attr_reader :connection_pool, :host_name_resolver, :load_balancing_strategy, :routing_context, :seed_router

        def fetch_routing_table(router_addresses, routing_table = nil)
        end

        def fetch_routing_table_from_seed_or_known
          seen_routers = []
          new_routing_table = fetch_routing_table_using_seed(seen_routers)
        end

        def fetch_routing_table_using_seed(seen_routers)
          resolved_addresses = host_name_resolver.resolve(seed_router)
          new_addresses = resolved_addresses - seen_routers
          fetch_routing_table(new_addresses)
        end

        def fresh_routing_table(access_mode)
          return routing_table unless routing_table.is_stale_for(access_mode)

          refresh_routing_table!
        end

        def rediscovery
          @rediscovery ||= Rediscovery.new(@routing_context)
        end

        def refresh_routing_table!
          return fetch_routing_table_from_seed_or_known if @use_seed_router

          fech_routing_table_from_known_or_seed
        end

        def routing_table
          @routing_table ||= RoutingTable.new([@seed_router])
        end
      end
    end
  end
end
