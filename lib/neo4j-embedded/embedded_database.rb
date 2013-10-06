module Neo4j::Embedded
  class EmbeddedDatabase
    class << self
      def connect(db_location, config={})
        EmbeddedSession.new(db_location, config)
      end

      def create_db(db_location)
        factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
        factory.newEmbeddedDatabase(db_location)
      end

      def factory_class
        Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory
        Java::OrgNeo4jTest::ImpermanentGraphDatabase
      end

    end
  end
end