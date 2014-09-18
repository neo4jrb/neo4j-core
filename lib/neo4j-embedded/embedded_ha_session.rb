require 'neo4j-enterprise'

Neo4j::Session.register_db(:ha_db) do |*args|
  Neo4j::Embedded::EmbeddedHaSession.new(*args)
end

module Neo4j::Embedded
  class EmbeddedHaSession < EmbeddedSession
    def start
      raise Error.new("Embedded HA Neo4j db is already running") if running?
      puts "Start embedded HA Neo4j db at #{db_location}"
      require 'ruby-debug'; debugger
      factory    = Java::OrgNeo4jGraphdbFactory::HighlyAvailableGraphDatabaseFactory.new
      db_service = factory.newHighlyAvailableDatabaseBuilder(db_location)

      raise Error.new("Need properties file for HA configuration") unless properties_file
      db_service.loadPropertiesFromFile(properties_file)
      @graph_db = db_service.newGraphDatabase()
      Neo4j::Session._notify_listeners(:session_available, self)
    end
  end
end
