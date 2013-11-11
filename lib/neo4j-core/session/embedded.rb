if RUBY_PLATFORM == 'java'
require "java"
Dir["#{Dir.pwd}/lib/neo4j-core/jars/*.jar"].each do |jar|
  jar = File.basename(jar)
  require "neo4j-core/jars/#{jar}"
end

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

      # Nodes
      def create_node(attributes, labels)
        labels = labels.map { |label| Label.new(label) }
        node = database.createNode(*labels)
      end
    end
  end
end
else
  class Neo4j::Session::Embedded
  end
end
