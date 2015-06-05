require 'neo4j-enterprise'

Neo4j::Session.register_db(:ha_db) do |*args|
  Neo4j::Embedded::EmbeddedHaSession.new(*args)
end

module Neo4j
  module Embedded
    class EmbeddedHaSession < EmbeddedSession
      def start
        fail Error, 'Embedded HA Neo4j db is already running' if running?
        puts "Start embedded HA Neo4j db at #{db_location}"
        factory    = Java::OrgNeo4jGraphdbFactory::HighlyAvailableGraphDatabaseFactory.new
        db_service = factory.newHighlyAvailableDatabaseBuilder(db_location)

        case
        when properties_file
          db_service.loadPropertiesFromFile(properties_file)
        when properties_map
          db_service.setConfig(properties_map)
        else
          fail Error, 'Need properties for HA configuration'
        end

        @graph_db = db_service.newGraphDatabase
        Neo4j::Session._notify_listeners(:session_available, self)
      end
    end
  end
end
