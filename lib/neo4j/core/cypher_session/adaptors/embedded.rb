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
            # I think that this is the best way to do a batch in embedded...
            # Should probably do within a transaction in case of errors...
            setup_queries!(queries, transaction, options)

            # transaction do
            self.class.instrument_transaction do
              self.class.instrument_queries(queries)

              execution_results = queries.map do |query|
                engine.execute(query.cypher, indifferent_params(query))
              end

              wrap_level = options[:wrap_level] || @options[:wrap_level]
              Responses::Embedded.new(execution_results, wrap_level: wrap_level).results
            end
            # end
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

          def indexes(session, label = nil)
            # Move these calls out to adaptors.rb?
            Neo4j::Core::Label.wait_for_schema_changes(session)

            Transaction.run(session) do
              graph_db = session.adaptor.graph_db

              args = []
              args << Java::OrgNeo4jGraphdb.DynamicLabel.label(label) if label

              graph_db.schema.get_indexes(*args).map { |definition| definition.property_keys.to_a }
            end
          end

          def constraints(session, label = nil, options = {})
            # Move these calls out to adaptors.rb?
            Neo4j::Core::Label.wait_for_schema_changes(session)

            Transaction.run(session) do
              args = []
              args << Java::OrgNeo4jGraphdb.DynamicLabel.label(label) if label

              constraint_definitions_for(session.adaptor.graph_db, args, options[:type])
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

          private

          def indifferent_params(query)
            params = query.parameters
            params.each { |k, v| params[k] = HashWithIndifferentAccess.new(params[k]) if v.is_a?(Hash) && !v.respond_to?(:nested_under_indifferent_access) }
            HashWithIndifferentAccess.new(params)
          end

          def engine
            @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
          end

          def constraint_definitions_for(graph_db, args, type = nil)
            constraint_definitions = graph_db.schema.get_constraints(*args).to_a
            constraint_definitions.select! { |d| d.constraint_type.to_s == type.to_s.upcase } if type
            constraint_definitions.map { |definition| definition.property_keys.to_a }
          end
        end
      end
    end
  end
end
