require "neo4j-community" if RUBY_PLATFORM == 'java'

module Neo4j
  module Session
    class Embedded
      def initialize(path)
        @db_location = path
        @running = false
      end

      def running?
        @running
      end

      def database
        @db
      end

      def start
        return false if @started
        @started = true
        factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
        @db = factory.newEmbeddedDatabase @db_location
        @running = true
      end

      def stop
        return false if @stopped
        @db.shutdown
        @running = false
        @stopped = true
      end
    end
  end
end