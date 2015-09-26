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

          def query(cypher_string, parameters = {})
            queries([[cypher_string, parameters]])[0]
          end

          def queries(_queries_and_parameters)
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

          instrument(:query, 'neo4j.core.cypher_query', %w(cypher pretty_cypher parameters context)) do |_, _start, _finish, _id, payload|
            params_string = (payload[:params] && payload[:params].size > 0 ? "| #{payload[:params].inspect}" : EMPTY)
            cypher = payload[:pretty_cypher] ? NEWLINE_W_SPACES + payload[:pretty_cypher].gsub(/\n/, NEWLINE_W_SPACES) : payload[:cypher]

            " #{ANSI::CYAN}#{payload[:context] || 'CYPHER'}#{ANSI::CLEAR} #{cypher} #{params_string}"
          end

          class << self
            def instrument_queries(queries_and_parameters)
              queries_and_parameters.each do |cypher, parameters|
                instrument_query(cypher, nil, parameters, nil) {}
              end
            end
          end
        end
      end
    end
  end
end
