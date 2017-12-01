require 'neo4j/core/cypher_session'
require 'neo4j/core/instrumentable'
require 'neo4j/core/label'
require 'neo4j-core/version'

module Neo4j
  module Core
    class CypherSession
      class CypherError < StandardError
        attr_reader :code, :original_message, :stack_trace

        def initialize(code = nil, original_message = nil, stack_trace = nil)
          @code = code
          @original_message = original_message
          @stack_trace = stack_trace

          msg = <<-ERROR
  Cypher error:
  #{ANSI::CYAN}#{code}#{ANSI::CLEAR}: #{original_message}
  #{stack_trace}
ERROR
          super(msg)
        end


        def self.new_from(code, message, stack_trace = nil)
          error_class_from(code).new(code, message, stack_trace)
        end

        def self.error_class_from(code)
          case code
          when /(ConstraintValidationFailed|ConstraintViolation)/
            SchemaErrors::ConstraintValidationFailedError
          when /IndexAlreadyExists/
            SchemaErrors::IndexAlreadyExistsError
          when /ConstraintAlreadyExists/ # ?????
            SchemaErrors::ConstraintAlreadyExistsError
          else
            CypherError
          end
        end
      end
      module SchemaErrors
        class ConstraintValidationFailedError < CypherError; end
        class ConstraintAlreadyExistsError < CypherError; end
        class IndexAlreadyExistsError < CypherError; end
      end
      class ConnectionFailedError < StandardError; end

      module Adaptors
        MAP = {}

        class Base
          include Neo4j::Core::Instrumentable

          gem_name, version = if defined?(::Neo4j::ActiveNode)
                                ['neo4j', ::Neo4j::VERSION]
                              else
                                ['neo4j-core', ::Neo4j::Core::VERSION]
                              end


          USER_AGENT_STRING = "#{gem_name}-gem/#{version} (https://github.com/neo4jrb/#{gem_name})"

          def connect(*_args)
            fail '#connect not implemented!'
          end

          attr_accessor :wrap_level

          Query = Struct.new(:cypher, :parameters, :pretty_cypher, :context)

          class QueryBuilder
            attr_reader :queries

            def initialize
              @queries = []
            end

            def append(*args)
              query = case args.map(&:class)
                      when [String], [String, Hash]
                        Query.new(args[0], args[1] || {})
                      when [::Neo4j::Core::Query]
                        args[0]
                      else
                        fail ArgumentError, "Could not determine query from arguments: #{args.inspect}"
                      end

              @queries << query
            end

            def query
              # `nil` sessions are just a workaround until
              # we phase out `Query` objects containing sessions
              Neo4j::Core::Query.new(session: nil)
            end
          end

          def query(session, *args)
            options = case args.size
                      when 3
                        args.pop
                      when 2
                        args.pop if args[0].is_a?(::Neo4j::Core::Query)
                      end || {}

            queries(session, options) { append(*args) }[0]
          end

          def queries(session, options = {}, &block)
            query_builder = QueryBuilder.new

            query_builder.instance_eval(&block)

            new_or_current_transaction(session, options[:transaction]) do |tx|
              query_set(tx, query_builder.queries, {commit: !options[:transaction]}.merge(options))
            end
          end

          %i[query_set
             version
             indexes
             constraints
             connected?].each do |method|
            define_method(method) do |*_args|
              fail "##{method} method not implemented on adaptor!"
            end
          end

          # If called without a block, returns a Transaction object
          # which can be used to call query/queries/mark_failed/commit
          # If called with a block, the Transaction object is yielded
          # to the block and `commit` is ensured.  Any uncaught exceptions
          # will mark the transaction as failed first
          def transaction(session)
            return self.class.transaction_class.new(session) if !block_given?

            begin
              tx = transaction(session)

              yield tx
            rescue => e
              tx.mark_failed if tx

              raise e
            ensure
              tx.close if tx
            end
          end

          def logger
            return @logger if @logger

            @logger = if @options[:logger]
                        @options[:logger]
                      else
                        Logger.new(logger_location).tap do |logger|
                          logger.level = logger_level
                        end
                      end
          end

          def setup_queries!(queries, transaction, options = {})
            fail 'Query attempted without a connection' if !connected?
            fail "Invalid transaction object: #{transaction.inspect}" if !transaction.is_a?(self.class.transaction_class)

            # context option not yet implemented
            self.class.instrument_queries(queries) unless options[:skip_instrumentation]
          end

          EMPTY = ''
          NEWLINE_W_SPACES = "\n  "

          instrument(:query, 'neo4j.core.cypher_query', %w[query]) do |_, _start, _finish, _id, payload|
            query = payload[:query]
            params_string = (query.parameters && !query.parameters.empty? ? "| #{query.parameters.inspect}" : EMPTY)
            cypher = query.pretty_cypher ? (NEWLINE_W_SPACES if query.pretty_cypher.include?("\n")).to_s + query.pretty_cypher.gsub(/\n/, NEWLINE_W_SPACES) : query.cypher

            " #{ANSI::CYAN}#{query.context || 'CYPHER'}#{ANSI::CLEAR} #{cypher} #{params_string}"
          end

          class << self
            def instrument_queries(queries)
              queries.each do |query|
                instrument_query(query) {}
              end
            end

            def transaction_class
              fail '.transaction_class method not implemented on adaptor!'
            end
          end

          private

          def new_or_current_transaction(session, tx, &block)
            if tx
              yield(tx)
            else
              transaction(session, &block)
            end
          end

          def validate_query_set!(transaction, _queries, _options = {})
            fail 'Query attempted without a connection' if !connected?
            fail "Invalid transaction object: #{transaction}" if !transaction.is_a?(self.class.transaction_class)
          end

          def logger_location
            @options[:logger_location] || STDOUT
          end

          def logger_level
            @options[:logger_level] || Logger::WARN
          end
        end
      end
    end
  end
end
