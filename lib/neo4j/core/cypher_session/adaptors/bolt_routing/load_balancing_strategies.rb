# frozen_string_literal: true

require 'neo4j/core/cypher_session/adaptors/bolt_routing/round_robin_array_index'

module Neo4j
  module Core
    module BoltRouting
      class LeastConenctedLoadBalancingStrategy
        def initialize(pool)
          @pool = pool
          @readers = RoundRobinArrayIndex.new
          @writers = RoundRobinArrayIndex.new
        end

        def select_reader(known_readers)
          select(known_readers, readers)
        end

        def select_writer(known_writers)
          select(known_writers, writers)
        end

        private

        attr_reader :pool, :readers, :writers

        def select(addresses, round_robin_index)
          return if addresses.empty?

          start_index = round_robin_index.next(addresses.size)
          index = start_index

          least_connected_address = nil
          least_active_connections = BigDecimal('Infinity')

          loop do
            address = addresses[index]
            active_connections = pool.active_resource_count(address)

            if active_connections < least_active_connections
              least_connected_address = address
              least_active_connections = active_connections
            end

            if index == addresses.size - 1
              index = 0
            else
              index += 1
            end

            break if index == start_index
          end

          least_connected_address
        end
      end
    end

    class RoundRobinLoadBalancingStrategy
      def initialize(pool)
        @pool = pool
        @readers = RoundRobinArrayIndex.new
        @writers = RoundRobinArrayIndex.new
      end

      def select_reader(known_readers)
        select(known_readers, readers)
      end

      def select_writer(known_writers)
        select(known_writers, writers)
      end

      private

      attr_reader :pool, :readers, :writers

      def select(addresses, round_robin_index)
        return if addresses.empty?

        index = round_robin_index.next(addresses.size)
        addresses[index]
      end
    end
  end
end
