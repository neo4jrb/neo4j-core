# frozen_string_literal: true

require 'neo4j/core/cypher_session/adaptors/single_connection'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/rediscovery'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/routing_table'

module Neo4j
  module Core
    module BoltRouting
      class LoadBalancer
        UNAUTHORIZED_ERROR_CODE = 'Neo.ClientError.Security.Unauthorized'

        def self.forget_router(routing_table, routers_array, router_index)
          address = routers_array[router_index]
          routing_table.forget_router(address) if routing_table && address
        end

        def initialize(host_port, routing_context, connection_pool, load_balancing_strategy, host_name_resolver)
          @seed_router = host_port
          @routing_context = routing_context
          @connection_pool = connection_pool
          @load_balancing_strategy = load_balancing_strategy
          @host_name_resolver = host_name_resolver
          @use_seed_router = false
        end

        def acquire_connection(access_mode)
          fresh_routing_table(access_mode).then(access_mode) do |routing_table, access_mode|
            if access_mode == :read
              address = load_balancing_strategy.select_reader(routing_table.readers)
              acquire_connection_to_server(address, 'read')
            elsif access_mode == :write
              address = load_balancing_strategy.select_writer(routing_table.writers)
              acquire_connection_to_server(address, 'write')
            else
              raise ArgumentError, "Illegal access mode: #{ access_mode }."
            end
          end.flat
        end

        def forget(address)
          routing_table.forget(address)
          connection_pool.purge(address)
        end

        def forget_writer(address)
          routing_table.forget_writer(address)
        end

        private

        attr_reader :connection_pool, :host_name_resolver, :load_balancing_strategy, :routing_context, :seed_router

        def acquire_connection_to_server(address, server_name)
          return Concurrent::Promises.rejected_future(StandardError.new("Failed to obtain connection towards #{ server_name } server. Known routing table is #{ routing_table.inspect }.")) if address.nil?
          connection_pool.acquire(address)
        end

        def apply_routing_table_if_possible!(new_routing_table)
          raise Neo4j::Core::CypherSession::ConnectionFailedError, "Could not perform discovery. No routing servers available. Known routing table: #{ routing_table.inspect }." if new_routing_table.nil?

          current_routing_table = routing_table

          @use_seed_router = true if new_routing_table.writers.empty?

          stale_servers = current_routing_table - new_routing_table
          stale_servers.each { |ss| connection_pool.purge(ss) }

          @routing_table = new_routing_table
        end

        def create_session_for_rediscovery(router_address)
          connection_pool.acquire(router_address).then do |connection|
            Neo4j::Core::CypherSession.new Neo4j::Core::CypherSession::Adaptors::SingleConnection.new(connection)
          end.rescue do |error|
            raise error if error.respond_to?(:code) && error.code == UNAUTHORIZED_ERROR_CODE
            nil
          end
        end

        def fetch_routing_table(router_addresses, routing_table = nil)
          router_addresses.each_with_index.reduce(Concurrent::Promises.fulfilled_future(nil)) do |refreshed_table_promise, (current_router, current_index)|
            refreshed_table_promise.then(router_addresses, routing_table, current_router, current_index) do |new_routing_table, router_address, routing_table, current_router, current_index|
              if new_routing_table.nil?
                previous_router_index = current_index - 1
                LoadBalancer.forget_router(routing_table, router_addresses, previous_router_index)

                create_session_for_rediscovery(current_router).then(current_router) do |session, current_router|
                  if session.nil?
                    nil
                  else
                    rediscovery.look_up_routing_table_on_router(session, current_router)
                  end
                end
              else
                new_routing_table
              end
            end
          end
        end

        def fetch_routing_table_from_seed_or_known
          seen_routers = Concurrent::Array.new
          fetch_routing_table_using_seed(seen_routers).then do |new_routing_table|
            if new_routing_table.nil?
              fetch_routing_table_using_known
            else
              @use_seed_router = false
              new_routing_table
            end
          end.flat.then do |new_routing_table|
            apply_routing_table_if_possible!(new_routing_table)
            new_routing_table
          end
        end

        def fetch_routing_table_from_known_or_seed
          fetch_routing_table_using_known.then do |new_routing_table|
            if new_routing_table.nil?
              fetch_routing_table_using_seed(routing_table.routers)
            else
              new_routing_table
            end
          end.flat.then do |new_routing_table|
            apply_routing_table_if_possible!(new_routing_table)
            new_routing_table
          end
        end

        def fetch_routing_table_using_known
          known_routers = routing_table.routers

          fetch_routing_table(known_routers, routing_table).then(known_routers) do |new_routing_table, known_routers|
            if new_routing_table.nil?
              last_router_index = known_routers.size - 1
              LoadBalancer.forget_router(routing_table, known_routers, last_router_index)

              nil
            else
              new_routing_table
            end
          end
        end

        def fetch_routing_table_using_seed(seen_routers)
          resolved_addresses = host_name_resolver.resolve(seed_router)
          resolved_addresses.then(seen_routers) do |router_addresses, seen_routers|
            new_addresses = router_addresses - seen_routers
            fetch_routing_table(new_addresses)
          end
        end

        def fresh_routing_table(access_mode)
          return Concurrent::Promises.fulfilled_future(routing_table) unless routing_table.stale_for?(access_mode)

          refresh_routing_table!
        end

        def rediscovery
          @rediscovery ||= Rediscovery.new(@routing_context)
        end

        def refresh_routing_table!
          if @use_seed_router
            fetch_routing_table_from_seed_or_known
          else
            fetch_routing_table_from_known_or_seed
          end
        end

        def routing_table
          @routing_table ||= RoutingTable.new([@seed_router])
        end
      end
    end
  end
end
