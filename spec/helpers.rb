require "tmpdir"

module Helpers
  module Rest
    class << self
      def run
        Neo4j::Session.stop if Neo4j::Session.running?
        Neo4j::Session.open :rest
      end

      def clean
        Neography::Rest.new.commit_transaction 'START n = node(*) MATCH n-[r?]-() WHERE ID(n)>0 DELETE n, r;'
      end
    end
  end

  module Embedded
    PATH = File.join(Dir.tmpdir, "neo4j-core-java")

    class << self
      def run
        Neo4j::Session.stop if Neo4j::Session.running?
        Neo4j::Session.open :impermamnent
      end

      def clean
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