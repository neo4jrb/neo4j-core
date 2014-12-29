module Neo4j::Embedded
  class EmbeddedDatabase

    class Error < StandardError
    end

    class << self
      def connect(db_location, config = {})
        if Neo4j::Session.current.respond_to?(:db_location) && Neo4j::Session.current.db_location == db_location
          return Neo4j::Session.current
        else
          EmbeddedSession.new(db_location, config)
        end
      end

      def create_db(db_location)
        puts "Start embedded Neo4j db at #{db_location}"
        factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
        factory.newEmbeddedDatabase(db_location)
      end

      def factory_class
        Java::OrgNeo4jTest::ImpermanentGraphDatabase
      end

    end
  end
end
