require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/adaptors/has_uri'
require 'neo4j/core/cypher_session/adaptors/bolt/pack_stream'
require 'neo4j/core/cypher_session/adaptors/bolt/chunk_writer_io'
require 'neo4j/core/cypher_session/responses/bolt'

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
          end

          def connect
            open_socket

            handshake

            init
          end

          def query_set(queries)
            setup_queries!(queries)

            send_query_jobs(queries).each do |message|
              if message.type != :success
                data = message.args[0]
                fail "Job did not complete successfully\n\n#{data['code']}\n#{data['message']}"
              end
            end

            queries.flat_map do |_query|
              Responses::Bolt.new(-> { flush_messages }).results
            end
          end

          def start_transaction
          end

          def end_transaction
          end

          def transaction_started?
          end

          def version
          end

          def connected?
            !!@socket
          end

          # Schema inspection methods
          def indexes_for_label(label)
          end

          def uniqueness_constraints_for_label(label)
          end


          instrument(:request, 'neo4j.core.bolt.request', %w(url body)) do |_, start, finish, _id, payload|
            ms = (finish - start) * 1000

            " #{ANSI::BLUE}BOLT REQUEST:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR} #{payload[:url]}"
          end

          private

          def send_query_jobs(queries)
            job = new_job
            queries.each do |query|
              job.add_message(:run, query.cypher, query.parameters || {})
              job.add_message(:pull_all)
            end
            send_job(job)

            flush_messages
          end

          def new_job
            Job.new(self)
          end

          def open_socket
            @socket = TCPSocket.open(host, port)
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
            job = new_job
            job.add_message(:init, USER_AGENT_STRING, principal: user, credentials: password, scheme: 'basic')

            send_job(job)
          end

          # Takes a Job object.
          # Sends it's messages to the server and returns an array of Message objects
          def send_job(job)
            log_message :C, :job, job
            sendmsg(job.chunked_packed_stream)
          end

          STREAM_INSPECTOR = lambda do |stream|
            stream.bytes.map { |byte| byte.to_s(16).rjust(2, '0') }.join(':')
          end

          def sendmsg(message)
            log_message :C, message

            @socket.sendmsg(message)
          end

          def recvmsg(size)
            @socket.recv(size).tap do |result|
              log_message :S, result
            end
          end

          def flush_messages
            flush_response.flat_map do |structures|
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

          def flush_response
            result = []

            while !(header = recvmsg(2)).empty? && (chunk_size = header.unpack('s>*')[0]) > 0
              log_message :S, :chunk_size, chunk_size

              chunk = recvmsg(chunk_size)

              unpacker = PackStream::Unpacker.new(StringIO.new(chunk))

              result << []
              while arg = unpacker.unpack_value!
                result[-1] << arg
              end
            end

            result
          end


          # Represents messages sent to or received from the server
          class Message
            TYPE_CODES = {
              # client message types
              init: 0x01,             # 0000 0001 // INIT <user_agent>
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
