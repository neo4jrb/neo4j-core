# frozen_string_literal: true

module Neo4j
  module Core
    module BoltRouting
      class RoutingTable
        MIN_ROUTERS = 1

        attr_reader :routers, :readers, :writers, :expiration_time

        def initialize(routers = [], readers = [], writers = [], expiration_time = 0)
          @routers = routers
          @readers = readers
          @writers = writers
          @expiration_time = expiration_time
        end

        def inspect
          "#<RoutingTable [@expiration_time=#{ expiration_time }, current_time=#{ Time.now.to_i }, @routers=[#{ routers.join(', ') }], @readers=[#{ readers.join(', ') }], @writers=[#{ writers.join(', ') }]]>"
        end

        def -(other_routing_table)
          all_servers - other_routing_table.all_servers
        end

        def all_servers
          (routers + readers + writers).uniq
        end

        def forget(address)
          @readers.delete(address)
          @writers.delete(address)
        end

        def forget_router(address)
          @routers.delete(address)
        end

        def forget_writer(address)
          @writers.delete(address)
        end

        def stale_for?(access_mode)
          expiration_time < Time.now.to_i ||
            routers.size < MIN_ROUTERS ||
            (access_mode == :read && readers.empty?) ||
            (access_mode == :write && writers.empty?)
        end
      end
    end
  end
end
