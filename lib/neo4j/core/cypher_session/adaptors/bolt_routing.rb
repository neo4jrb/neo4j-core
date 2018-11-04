# frozen_string_literal: true

require 'concurrent'
require 'concurrent-edge'
require 'io/wait'
require 'socket'
require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/adaptors/bolt/pack_stream'
require 'neo4j/core/cypher_session/responses/bolt_routing'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/connection'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/dns_host_name_resolver'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/load_balancing_strategies'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/load_balancer'
require 'neo4j/core/cypher_session/adaptors/bolt_routing/pool'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class BoltRouting < Bolt
          include Adaptors::HasUri

          SUPPORTED_VERSIONS = [1, 0, 0, 0].freeze

          VERSION = '0.0.1'.freeze

          default_url('bolt+routing://neo4:neo4j@localhost:7687')

          validate_uri do |uri|
            uri.scheme == 'bolt+routing'
          end

          def initialize(url, options = {})
            self.url = url

            @host_port = "#{ host }:#{ port }"
            @options = options
            @routing_context = @uri.query
            @net_tcp_client_options = {
              connect_timeout: options.fetch(:connect_timeout, 10),
              read_timeout: options.fetch(:read_timeout, -1),
              ssl: options.fetch(:ssl, false),
              write_timeout: options.fetch(:write_timeout, -1),
            }
          end

          def connect; end

          # FIXME: Drive this down to the connection pool or track active
          # connections in the adapter.
          def connected?
            true
          end

          def queries(session, options = {}, &block)
            query_builder = QueryBuilder.new

            query_builder.instance_eval(&block)

            write_queries = query_builder.queries.count { |q| /(CREATE|DELETE|DETACH|DROP|SET|REMOVE|FOREACH|MERGE|CALL)/.match?(q.cypher) }
            access_mode = write_queries.zero? ? :read : :write

            new_or_current_transaction(session, access_mode, options[:transaction]) do |tx|
              query_set(tx, query_builder.queries, { commit: !options[:transaction] }.merge(options))
            end
          end

          def query_set(transaction, queries, options = {})
            setup_queries!(queries, transaction, skip_instrumentation: options[:skip_instrumentation])

            conn = if transaction.connection.nil?
                     connection_provider.acquire_connection(transaction.access_mode)
                   else
                     Concurrent::Promises.fulfilled_future(transaction.connection)
                   end

            responses = conn.then(queries, options, transaction) do |conn, queries, options, transaction|
              transaction.connection ||= conn
              self.class.instrument_request(self) do
                send_query_jobs(conn.client, queries)
                build_response(conn.client, queries, options[:wrap_level] || @options[:wrap_level])
              end
            end

            responses.value!
          end

          # FIXME: Drive this down to the connection pool or track active
          # connections in the adapter.
          def ssl?
            !!@options.fetch(:ssl, false)
          end

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

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/bolt_routing'
            Neo4j::Core::CypherSession::Transactions::BoltRouting
          end

          private

          BYTE_STRINGS = (0..255).map { |byte| byte.to_s(16).rjust(2, '0') }

          GOGOBOLT = "\x60\x60\xB0\x17"

          STREAM_INSPECTOR = lambda do |stream|
            stream.bytes.map { |byte| BYTE_STRINGS[byte] }.join(':')
          end

          attr_reader :host_port, :routing_context

          def build_response(client, queries, wrap_level)
            catch(:cypher_bolt_failure) do
              Responses::BoltRouting.new(queries, client, method(:flush_messages), wrap_level: wrap_level).results
            end.tap do |error_data|
              handle_failure(client, error_data) unless error_data.is_a?(Array)
            end
          end

          def close_socket(connection)
            connection.client.close
          end

          def connect_socket(host_port, release)
            client = open_socket(host_port)

            handshake(client)

            init(client)

            message = flush_messages(client)[0]
            return Neo4j::Core::BoltRouting::Connection.new(host_port, client, release) if message.type == :success

            data = message.args[0]
            logger.error { "Init did not complete successfully\n\n#{data['code']}\n#{data['message']}" }
            release.call(host_port, client)
            nil
          end

          def connection_provider
            @connection_provider ||= Neo4j::Core::BoltRouting::LoadBalancer.new(host_port, routing_context, pool, load_balancing_strategy, resolver)
          end

          def flush_messages(client)
            if structures = flush_response(client)
              structures.map do |structure|
                Message.new(structure.signature, *structure.list).tap do |message|
                  log_message :S, message.type, message.args.join(' ') if logger.debug?
                end
              end
            end
          end

          def flush_response(client)
            chunk = String.new

            while !(header = recvmsg(client, 2)).empty? && (chunk_size = header.unpack('s>*')[0]) > 0
              log_message :S, :chunk_size, chunk_size

              chunk << recvmsg(client, chunk_size)
            end

            unpacker = PackStream::Unpacker.new(StringIO.new(chunk))
            [].tap { |r| while arg = unpacker.unpack_value!; r << arg; end }
          end

          def handshake(client)
            log_message :C, :handshake, nil

            sendmsg(client, GOGOBOLT + SUPPORTED_VERSIONS.pack('l>*'))

            agreed_version = recvmsg(client, 4).unpack('l>*')[0]

            if agreed_version.zero?
              client.close
              logger.error { "Couldn't agree on a version (Sent versions #{SUPPORTED_VERSIONS.inspect})" }
            end

            logger.debug { "Agreed to version: #{agreed_version}" }
          end

          def handle_failure(client, error_data)
            flush_messages(client)

            send_job(client) do |job|
              job.add_message(:ack_failure)
            end

            fail 'Excepted SUCCESS for ACK_FAILURE' if flush_messages(client)[0].type != :success

            fail CypherError.new_from(error_data['code'], error_data['message'])
          end

          def init(client)
            send_job(client) do |job|
              job.add_message(:init, USER_AGENT_STRING, principal: user, credentials: password, scheme: 'basic')
            end
          end

          def load_balancing_strategy
            @load_balancing_strategy ||= begin
                                           strategy = @options.fetch(:load_balancing_strategy, :least_connected).to_sym
                                           return Neo4j::Core::BoltRouting::RoundRobinLoadBalancingStrategy.new(pool) if strategy == :round_robin
                                           return Neo4j::Core::BoltRouting::LeastConenctedLoadBalancingStrategy.new(pool) if strategy == :least_connected
                                           raise ArgumentError, "Unknown load balancing strategy: `#{ strategy }`."
                                         end
          end

          def new_or_current_transaction(session, access_mode, tx, &block)
            if tx && tx.access_mode == access_mode
              yield(tx)
            else
              transaction(session, access_mode, &block)
            end
          end

          def open_socket(host_port)
            Net::TCPClient.new(@net_tcp_client_options.merge(buffered: false, server: host_port))
          rescue Errno::ECONNREFUSED => e
            raise Neo4j::Core::CypherSession::ConnectionFailedError, e.message
          end

          def pool
            @pool ||= Neo4j::Core::BoltRouting::Pool.new create: method(:connect_socket),
                                                         destroy: method(:close_socket),
                                                         validate: method(:validate_socket)
          end

          def recvmsg(client, size)
            client.read(size) do |result|
              log_message :S, result
            end
          end

          def resolver
            @resolver ||= Neo4j::Core::BoltRouting::DNSHostNameResolver.new
          end

          def send_job(client)
            new_job.tap do |job|
              yield job
              log_message :C, :job, job
              sendmsg(client, job.chunked_packed_stream)
            end
          end

          def send_query_jobs(client, queries)
            send_job(client) do |job|
              queries.each do |query|
                job.add_message(:run, query.cypher, query.parameters || {})
                job.add_message(:pull_all)
              end
            end
          end

          def sendmsg(client, message)
            log_message :C, message
            client.write(message)
          end

          def validate_socket(connection)
            connection.client.alive?
          end
        end
      end
    end
  end
end
