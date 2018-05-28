require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/responses/embedded'
require 'active_support/hash_with_indifferent_access'

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
            # I think that this is the best way to do a batch in embedded...
            # Should probably do within a transaction in case of errors...
            setup_queries!(queries, transaction, options)

            self.class.instrument_transaction do
              Responses::Embedded.new(execution_results(queries), wrap_level: options[:wrap_level] || @options[:wrap_level]).results
            end
          rescue Java::OrgNeo4jCypher::CypherExecutionException, Java::OrgNeo4jCypher::SyntaxException => e
            raise CypherError.new_from(e.status.to_s, e.message) # , e.stack_track.to_a
          end

          def version(_session)
            if defined?(::Neo4j::Community)
              ::Neo4j::Community::NEO_VERSION
            elsif defined?(::Neo4j::Enterprise)
              ::Neo4j::Enterprise::NEO_VERSION
            else
              fail 'Could not determine embedded version!'
            end
          end

          def indexes(session, _label = nil)
            Transaction.run(session) do
              graph_db = session.adaptor.graph_db

              graph_db.schema.get_indexes.map do |definition|
                {properties: definition.property_keys.map(&:to_sym),
                 label: definition.label.to_s.to_sym}
              end
            end
          end

          CONSTRAINT_TYPES = {
            'UNIQUENESS' => :uniqueness
          }
          def constraints(session)
            Transaction.run(session) do
              all_labels(session).flat_map do |label|
                graph_db.schema.get_constraints(label).map do |definition|
                  {label: label.to_s.to_sym,
                   properties: definition.property_keys.map(&:to_sym),
                   type: CONSTRAINT_TYPES[definition.get_constraint_type.to_s]}
                end
              end
            end
          end

          def self.transaction_class
            require 'neo4j/core/cypher_session/transactions/embedded'
            Neo4j::Core::CypherSession::Transactions::Embedded
          end

          def connected?
            !!@graph_db
          end

          instrument(:transaction, 'neo4j.core.embedded.transaction', []) do |_, start, finish, _id, _payload|
            ms = (finish - start) * 1000

            " #{ANSI::BLUE}EMBEDDED CYPHER TRANSACTION:#{ANSI::CLEAR} #{ANSI::YELLOW}#{ms.round}ms#{ANSI::CLEAR}"
          end

          def default_subscribe
            subscribe_to_transaction
          end

          private

          def execution_results(queries)
            queries.map do |query|
              engine.execute(query.cypher, indifferent_params(query))
            end
          end

          def all_labels(session)
            Java::OrgNeo4jTooling::GlobalGraphOperations.at(session.adaptor.graph_db).get_all_labels.to_a
          end

          def indifferent_params(query)
            params = query.parameters
            params.each { |k, v| params[k] = HashWithIndifferentAccess.new(params[k]) if v.is_a?(Hash) && !v.respond_to?(:nested_under_indifferent_access) }
            HashWithIndifferentAccess.new(params)
          end

          def engine
            @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
          end

          def constraint_definitions_for(graph_db, label); end
        end
      end
    end
  end
end
