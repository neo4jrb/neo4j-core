require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/adaptors/bolt/pack_stream'
require 'neo4j/core/cypher_session/adaptors/bolt/chunk_writer_io'
require 'neo4j/core/cypher_session/responses/bolt'
require 'io/wait'
require 'socket'

# TODO: Work with `Query` objects
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class Bolt < Base
          include Adaptors::HasUri
          default_url('bolt://neo4:neo4j@localhost:7687')
          validate_uri do |uri|
            uri.scheme == 'bolt'
          end

          SUPPORTED_VERSIONS = [1, 0, 0, 0].freeze
          VERSION = '0.0.1'.freeze

          def initialize(url, options = {})
            self.url = url
            @options = options

            open_socket
          end

          def connect
            handshake

            init

            message = flush_messages[0]
            return if message.type == :success

            data = message.args[0]
            fail "Init did not complete successfully\n\n#{data['code']}\n#{data['message']}"
          end

          def query_set(transaction, queries, options = {})
            setup_queries!(queries, transaction, skip_instrumentation: options[:skip_instrumentation])

            if @socket.ready?
              debug_remaining_buffer
              fail "Making query, but expected there to be no buffer remaining!\n"\
                   "Queries: #{queries.map(&:cypher)}"
            end

            self.class.instrument_request do
              send_query_jobs(queries)

              build_response(queries, options[:wrap_level] || @options[:wrap_level])
            end
          end

          def version(session)
            result = query(session, 'CALL dbms.components()', {}, skip_instrumentation: true)

            # BTW: community / enterprise could be retrieved via `result.first.edition`
            result.first.versions[0]
          end

          def connected?
            !!@socket
          end

          def indexes(session)
            result = query(session, 'CALL db.indexes()', {}, skip_instrumentation: true)

            result.map do |row|
              label, property = row.description.match(/INDEX ON :([^\(]+)\(([^\)]+)\)/)[1, 2]
              {type: row.type.to_sym, label: label.to_sym, properties: [property.to_sym], state: row.state.to_sym}
            end
          end

          def constraints(session)
            result = query(session, 'CALL db.indexes()', {}, skip_instrumentation: true)

            result.select { |row| row.type == 'node_unique_property' }.map do |row|
              label, property = row.description.match(/INDEX ON :([^\(]+)\(([^\)]+)\)/)[1, 2]
              {type: :uniqueness, label: label.to_sym, properties: [property.to_sym]}
            end
          end

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/bolt'
            Neo4j::Core::CypherSession::Transactions::Bolt
          end

          instrument(:request, 'neo4j.core.bolt.request', %w[url body]) do |_, start, finish, _id, payload|
            ms = (finish - start) * 1000

            " #{ANSI::BLUE}BOLT REQUEST:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{payload[:url]}"
          end

          private

          def build_response(queries, wrap_level)
            catch(:cypher_bolt_failure) do
              Responses::Bolt.new(queries, method(:flush_messages), wrap_level: wrap_level).results
            end.tap do |error_data|
              handle_failure!(error_data) if !error_data.is_a?(Array)
            end
          end

          def handle_failure!(error_data)
            flush_messages

            send_job do |job|
              job.add_message(:ack_failure)
            end
            fail 'Expected SUCCESS for ACK_FAILURE' if flush_messages[0].type != :success

            fail CypherError.new_from(error_data['code'], error_data['message'])
          end

          def debug_remaining_buffer
            logger.debug 'Remaining buffer:'

            i = 0
            while @socket.ready?
              i += 1
              logger.debug "Message set #{i}:"
              flush_messages
            end
          end

          def send_query_jobs(queries)
            send_job do |job|
              queries.each do |query|
                job.add_message(:run, query.cypher, query.parameters || {})
                job.add_message(:pull_all)
              end
            end
          end

          def new_job
            Job.new(self)
          end

          def open_socket
            @socket = TCPSocket.open(host, port)
          rescue Errno::ECONNREFUSED => e
            raise Neo4j::Core::CypherSession::ConnectionFailedError, e.message
          end

          GOGOBOLT = "\x60\x60\xB0\x17"
          def handshake
            log_message :C, :handshake, nil

            sendmsg(GOGOBOLT + SUPPORTED_VERSIONS.pack('l>*'))

            agreed_version = recvmsg(4).unpack('l>*')[0]

            if agreed_version.zero?
              @socket.shutdown(Socket::SHUT_RDWR)
              @socket.close

              fail "Couldn't agree on a version (Sent versions #{SUPPORTED_VERSIONS.inspect})"
            end

            logger.debug "Agreed to version: #{agreed_version}"
          end

          def init
            send_job do |job|
              job.add_message(:init, USER_AGENT_STRING, principal: user, credentials: password, scheme: 'basic')
            end
          end

          # Allows you to send messages to the server
          # Returns an array of Message objects
          def send_job
            new_job.tap do |job|
              yield job
              log_message :C, :job, job
              sendmsg(job.chunked_packed_stream)
            end
          end

          STREAM_INSPECTOR = lambda do |stream|
            stream.bytes.map { |byte| byte.to_s(16).rjust(2, '0') }.join(':')
          end

          def sendmsg(message)
            log_message :C, message

            @socket.send(message, 0)
          end

          def recvmsg(size, timeout = timeout_option)
            Timeout.timeout(timeout) do
              @socket.recv(size).tap do |result|
                log_message :S, result
              end
            end
          rescue Timeout::Error
            raise "Timed out waiting for #{size} bytes from Neo4j (after #{timeout} seconds)"
          end

          def flush_messages
            if structures = flush_response
              structures.map do |structure|
                Message.new(structure.signature, *structure.list).tap do |message|
                  log_message :S, message.type, message.args.join(' ')
                end
              end
            end
          end

          def log_message(side, *args)
            if args.size == 1
              logger.debug "#{side}: #{STREAM_INSPECTOR.call(args[0])}"
            else
              type, message = args
              logger.debug "#{side}: #{ANSI::CYAN}#{type.to_s.upcase}#{ANSI::CLEAR} #{message}"
            end
          end

          # Replace with Enumerator?
          def flush_response
            chunk = ''

            while !(header = recvmsg(2)).empty? && (chunk_size = header.unpack('s>*')[0]) > 0
              log_message :S, :chunk_size, chunk_size

              chunk << recvmsg(chunk_size)
            end

            unpacker = PackStream::Unpacker.new(StringIO.new(chunk))
            [].tap { |r| while arg = unpacker.unpack_value!; r << arg; end }
          end

          def timeout_option
            @options.fetch(:timeout) { 10 }
          end

          # Represents messages sent to or received from the server
          class Message
            TYPE_CODES = {
              # client message types
              init: 0x01,             # 0000 0001 // INIT <user_agent>
              ack_failure: 0x0E,      # 0000 1110 // ACK_FAILURE
              reset: 0x0F,            # 0000 1111 // RESET
              run: 0x10,              # 0001 0000 // RUN <statement> <parameters>
              discard_all: 0x2F,      # 0010 1111 // DISCARD *
              pull_all: 0x3F,         # 0011 1111 // PULL *

              # server message types
              success: 0x70,          # 0111 0000 // SUCCESS <metadata>
              record: 0x71,           # 0111 0001 // RECORD <value>
              ignored: 0x7E,          # 0111 1110 // IGNORED <metadata>
              failure: 0x7F           # 0111 1111 // FAILURE <metadata>
            }.freeze

            CODE_TYPES = TYPE_CODES.invert

            def initialize(type_or_code, *args)
              @type_code = Message.type_code_for(type_or_code)
              fail "Invalid message type: #{@type_code.inspect}" if !@type_code
              @type = CODE_TYPES[@type_code]

              @args = args
            end

            def struct
              PackStream::Structure.new(@type_code, @args)
            end

            def to_s
              "#{ANSI::GREEN}#{@type.to_s.upcase}#{ANSI::CLEAR} #{@args.inspect if !@args.empty?}"
            end

            def packed_stream
              PackStream::Packer.new(struct).packed_stream
            end

            def value
              return if @type != :record
              @args.map do |arg|
                # Assuming result is Record
                field_names = arg[1]

                field_values = arg[2].map do |field_value|
                  Message.interpret_field_value(field_value)
                end

                Hash[field_names.zip(field_values)]
              end
            end

            attr_reader :type, :args

            def self.type_code_for(type_or_code)
              type_or_code.is_a?(Integer) ? type_or_code : TYPE_CODES[type_or_code]
            end

            def self.interpret_field_value(value)
              if value.is_a?(Array) && (1..3).cover?(value[0])
                case value[0]
                when 1
                  {type: :node, identity: value[1],
                   labels: value[2], properties: value[3]}
                end
              else
                value
              end
            end
          end

          # Represents a set of messages to send to the server
          class Job
            def initialize(session)
              @messages = []
              @session = session
            end

            def add_message(type, *args)
              @messages << Message.new(type, *args)
            end

            def chunked_packed_stream
              io = ChunkWriterIO.new

              @messages.each do |message|
                io.write(message.packed_stream)
                io.flush(true)
              end

              io.rewind
              io.read
            end

            def to_s
              @messages.join(' | ')
            end
          end
        end
      end
    end
  end
end
