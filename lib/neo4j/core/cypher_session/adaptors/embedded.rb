require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/responses/embedded'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class Embedded < Base
          attr_reader :graph_db, :path

          def initialize(path, options = {})
            fail 'JRuby is required for embedded mode' if RUBY_PLATFORM != 'java'
            # TODO: Will this cause an error if a new path is specified?
            fail ArgumentError, "Invalid path: #{path}" if File.file?(path)
            FileUtils.mkdir_p(path)

            @path = path
            @options = options
          end

          def connect
            factory    = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
            db_service = factory.newEmbeddedDatabaseBuilder(@path)
            db_service.loadPropertiesFromFile(@options[:properties_file]) if @options[:properties_file]
            db_service.setConfig(@options[:properties_map])               if @options[:properties_map]

            @graph_db = db_service.newGraphDatabase
          end

          def query_set(transaction, queries, options = {})
            validate_query_set!(transaction, queries, options)

            self.class.instrument_transaction do
              self.class.instrument_queries(queries)

              execution_results = queries.map do |query|
                engine.execute(query.cypher, indifferent_params(query))
              end

              Responses::Embedded.new(execution_results, options).results
            end
          ensure
            transaction.close if options.delete(:commit)
          end

          def version
            if defined?(::Neo4j::Community)
              ::Neo4j::Community::NEO_VERSION
            elsif defined?(::Neo4j::Enterprise)
              ::Neo4j::Enterprise::NEO_VERSION
            else
              fail 'Could not determine embedded version!'
            end
          end

          def constraints(_session, _label = nil, _options = {})
            require 'pry'
          end

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/embedded'
            Neo4j::Core::CypherSession::Transactions::Embedded
          end

          instrument(:transaction, 'neo4j.core.embedded.transaction', []) do |_, start, finish, _id, _payload|
            ms = (finish - start) * 1000

            " #{ANSI::BLUE}EMBEDDED CYPHER TRANSACTION:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR}"
          end

          private

          def indifferent_params(query)
            params = query.parameters
            params.each { |k, v| params[k] = HashWithIndifferentAccess.new(params[k]) if v.is_a?(Hash) && !v.respond_to?(:nested_under_indifferent_access) }
            HashWithIndifferentAccess.new(params)
          end

          def engine
            @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
          end
        end
      end
    end
  end
end
