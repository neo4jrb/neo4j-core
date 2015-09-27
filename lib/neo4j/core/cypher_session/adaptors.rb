require 'neo4j/core/instrumentable'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        MAP = {}

        class Base
          include Neo4j::Core::Instrumentable

          def connect(*_args)
            fail '#connect not implemented!'
          end

          Query = Struct.new(:cypher, :parameters, :pretty_cypher, :context)

          class QueryBuilder
            attr_reader :queries

            def initialize
              @queries = []
            end

            def query(cypher, parameters = {})
              @queries << Query.new(cypher, parameters)
            end
          end

          def query(cypher, parameters = {})
            queries do |batch|
              batch.query(cypher, parameters)
            end[0]
          end

          def queries
            query_builder = QueryBuilder.new

            yield query_builder

            query_set(query_builder.queries)
          end

          def query_set(queries)
            fail '#queries not implemented!'
          end

          def start_transaction(*_args)
            fail '#start_transaction not implemented!'
          end

          def end_transaction(*_args)
            fail '#end_transaction not implemented!'
          end

          # Uses #start_transaction and #end_transaction to allow
          # execution of queries within a block to be part of a
          # full transaction
          def transaction
            start_transaction

            yield
          ensure
            end_transaction
          end

          EMPTY = ''
          NEWLINE_W_SPACES = "\n  "

          instrument(:query, 'neo4j.core.cypher_query', %w(query)) do |_, _start, _finish, _id, payload|
            query = payload[:query]
            params_string = (query.parameters && query.parameters.size > 0 ? "| #{query.parameters.inspect}" : EMPTY)
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
        end
      end
    end
  end
end
