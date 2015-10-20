Neo4j::Community.load_test_jars!

Neo4j::Session.register_db(:impermanent_db) do |*args|
  Neo4j::Embedded::EmbeddedImpermanentSession.new(*args)
end

module Neo4j
  module Embedded
    class EmbeddedImpermanentSession < EmbeddedSession
      def start
        fail Error, 'Embedded Neo4j db is already running' if running?
        @graph_db = Java::OrgNeo4jTest::TestGraphDatabaseFactory.new.newImpermanentDatabase
        Neo4j::Session._notify_listeners(:session_available, self)
      end
    end
  end
end
