require "tmpdir"
load "Rakefile"

module Helpers
  module Rest
    class << self
      def stop
        Rake.application['neo4j:stop'].invoke
      end

      def clean_start
        Rake.application[:clean].invoke
        Rake.application['neo4j:start'].invoke
      end
    end
  end

  module Embedded
    PATH = File.join(Dir.tmpdir, "neo4j-core-java")

    class << self
      def start
        Neo4j::Session.stop if Neo4j::Session.running?
        Neo4j::Session.open :impermamnent
      end

      def clean_start
        graph_db = Neo4j::Session.current.graph_db
        ggo = Java::OrgNeo4jTooling::GlobalGraphOperations.at(graph_db)

        tx = graph_db.begin_tx
        ggo.all_relationships.each do |rel|
          rel.delete
        end
        tx.success
        tx.finish

        tx = graph_db.begin_tx
        ggo.all_nodes.each do |node|
          node.delete
        end
        tx.success
        tx.finish
        Neo4j::Session.stop
      end
    end
  end
end