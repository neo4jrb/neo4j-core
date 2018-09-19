# frozen_string_literal: true

require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/adaptors/bolt/pack_stream'
require 'neo4j/core/cypher_session/adaptors/bolt/chunk_writer_io'
require 'neo4j/core/cypher_session/responses/bolt'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/load_balancing_strategies'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/load_balancer'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/pool'
require 'io/wait'
require 'socket'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class BoltRouting < Base
          SUPPORTED_VERSIONS = [1, 0, 0, 0].freeze
          VERSION = '0.0.1'.freeze

          def initialize(url = 'bolt+routing://neo4:neo4j@localhost:7687', routing_context = nil, options = {})
            uri = URI(url)
            @host_port = "#{ uri.host }:#{ uri.port }"
            @options = options
            @routing_context = routing_context
            @url = url
            @net_tcp_client_options = {
              connect_timeout: options.fetch(:connect_timeout, 10),
              read_timeout: options.fetch(:read_timeout, -1),
              ssl: options.fetch(:ssl, {}),
              write_timeout: options.fetch(:write_timeout, -1),
            }
          end

          private

          attr_reader :options, :routing_context

          def connection_provider

          end

          def load_balancing_strategy
            @load_balancing_strategy ||= do
                                           strategy = @options.fetch(:load_balancing_strategy, :least_connected).to_sym
                                           return Neo4j::Core::BoltRouting::RoundRobinLoadBalancingStrategy.new(pool) if strategy == :round_robin
                                           return Neo4j::Core::BoltRouting::LeastConenctedLoadBalancingStrategy.new(pool) if strategy == :least_connected
                                           raise ArgumentError, "Unknown load balancing strategy: `#{ strategy }`."
                                         end
          end

          def open_socket(host_port)
            Net::TCPClient.new(@net_tcp_client_options.merge(buffered: false, server: host_port))
          rescue Errno::ECONNREFUSED => e
            raise Neo4j::Core::CypherSession::ConnectionFailedError, e.message
          end

          def pool
            @pool ||=Neo4j::Core::BoltRouting::Pool.new create: method(:open_socket)
          end

          def resolver
            @resolver ||= Neo4j::Core::BoltRouting::DNSHostNameResolver.new
          end
        end
      end
    end
  end
end
