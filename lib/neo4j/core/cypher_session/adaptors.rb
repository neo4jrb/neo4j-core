
module Neo4j
  module Core
    class CypherSession
      module Adaptors
        MAP = {}

        class Base
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

          class << self
            EMPTY = ''
            NEWLINE_W_SPACES = "\n  "

            # Missing context
            def subscribe_to_queries
              ActiveSupport::Notifications.subscribe('neo4j.cypher_query') do |_, start, finish, _id, payload|
                ms = (finish - start) * 1000
                queries_and_parameters = payload[:queries_and_parameters]
                lines = []
                lines << "#{ANSI::CYAN}CYPHER#{ANSI::CLEAR}: #{queries_and_parameters.size} queries in #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR}"

                queries_and_parameters.each do |query, parameters|
                  params_string = (parameters && parameters.size > 0 ? "| #{parameters.inspect}" : EMPTY)

                  lines << "  #{query} #{params_string}"
                end

                yield lines.join("\n")
              end
            end

            def instrument_queries(queries_and_parameters, options = {})
              ActiveSupport::Notifications.instrument('neo4j.cypher_query',
                                                      queries_and_parameters: queries_and_parameters,
                                                      context: options[:context]) do
                yield
              end
            end
          end
        end
      end
    end
  end
end
