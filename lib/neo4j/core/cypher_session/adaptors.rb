require 'neo4j/core/cypher_session'
require 'neo4j/core/instrumentable'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        MAP = {}

        class Base
          include Neo4j::Core::Instrumentable

          gem, version = if defined?(::Neo4j::ActiveNode)
                           ['neo4j', ::Neo4j::VERSION]
                         else
                           ['neo4j-core', ::Neo4j::Core::VERSION]
                         end


          USER_AGENT_STRING = "#{gem}-gem/#{version} (https://github.com/neo4jrb/#{gem})"

          def connect(*_args)
            fail '#connect not implemented!'
          end

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

          def query(*args)
            queries { append(*args) }[0]
          end

          def queries(&block)
            query_builder = QueryBuilder.new

            query_builder.instance_eval(&block)

            query_set(query_builder.queries)
          end

          def query_set(_queries)
            fail '#queries not implemented!'
          end

          def start_transaction(*_args)
            fail '#start_transaction not implemented!'
          end

          def end_transaction(*_args)
            fail '#end_transaction not implemented!'
          end

          def transaction_started?(*_args)
            fail '#transaction_started? not implemented!'
          end

          def version(*_args)
            fail '#version not implemented!'
          end

          # Schema inspection methods
          def indexes_for_label(*_args)
            fail '#indexes_for_label not implemented!'
          end

          def uniqueness_constraints_for_label(*_args)
            fail '#uniqueness_constraints_for_label not implemented!'
          end

          def logger
            return @logger if @logger

            if @options[:logger]
              @logger = @options[:logger]
            else
              @logger = Logger.new(logger_location).tap do |logger|
                logger.level = logger_level
              end
            end
          end

          # Uses #start_transaction and #end_transaction to allow
          # execution of queries within a block to be part of a
          # full transaction
          def transaction
            start_transaction

            yield
          ensure
            end_transaction if transaction_started?
          end

          EMPTY = ''
          NEWLINE_W_SPACES = "\n  "

          instrument(:query, 'neo4j.core.cypher_query', %w(query)) do |_, _start, _finish, _id, payload|
            query = payload[:query]
            params_string = (query.parameters && !query.parameters.empty? ? "| #{query.parameters.inspect}" : EMPTY)
            cypher = query.pretty_cypher ? NEWLINE_W_SPACES + query.pretty_cypher.gsub(/\n/, NEWLINE_W_SPACES) : query.cypher

            " #{ANSI::CYAN}#{query.context || 'CYPHER'}#{ANSI::CLEAR} #{cypher} #{params_string}"
          end

          class << self
            def instrument_queries(queries)
              queries.each do |query|
                instrument_query(query) {}
              end
            end
          end

          private

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
