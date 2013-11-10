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
    class << self
      def tmp_path
        File.join(Dir.tmpdir, "neo4j-core-java")
      end

      def stop
        Neo4j::Session.stop if Neo4j::Session.running?
      end

      def clean_start
        Neo4j::Session.stop if Neo4j::Session.running?
        session = Neo4j::Session.new :embedded, tmp_path
        session.start
        graph_db = session.database
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
        session.stop
      end
    end
  end
end