require 'neo4j/core/cypher_session/adaptors'
require 'neo4j/core/cypher_session/responses/embedded'

module Neo4j
  module Core
    class CypherSession
      module Adaptors
        class Embedded < Base
          def initialize(path, options = {})
            puts 'init...'
            fail 'JRuby is required for embedded mode' if RUBY_PLATFORM != 'java'

            @path = path
            @options = options
          end

          def connect
            puts 'connect...'
            factory    = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
            db_service = factory.newEmbeddedDatabaseBuilder(@path)
            db_service.loadPropertiesFromFile(@options[:properties_file]) if @options[:properties_file]
            db_service.setConfig(@options[:properties_map])               if @options[:properties_map]

            @graph_db = db_service.newGraphDatabase
          end

          def queries(queries_and_parameters)
            puts 'queries...'
            # I think that this is the best way to do a batch in embedded...
            # Should probably do within a transaction in case of errors...

            execution_results = queries_and_parameters.map do |query, parameters|
              engine.execute(query, HashWithIndifferentAccess.new(parameters))
            end

            Responses::Embedded.new(execution_results).results
          end

          private

          def engine
            @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
          end
        end
      end
    end
  end
end
