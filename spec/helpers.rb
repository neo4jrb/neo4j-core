require "tmpdir"
load "Rakefile"

module Helpers
  module Rest
    class << self
      def stop
        Rake.application['neo4j:stop'].invoke
        Neo4j::Session.stop
      end

      def clean_start
        Rake.application['neo4j:reset'].invoke
        Neo4j::Session.stop if Neo4j::Session.running?
        Neo4j::Session.new :rest
        # Neo4j::Session.stop if Neo4j::Session.running?
        # Neo4j::Session.new :rest
        # query = <<-EOQ
        # START n = node(*)
        # MATCH n-[r?]-()
        # WHERE ID(n) > 0
        # DELETE n, r
        # EOQ
        # Neo4j::Session.current.neo.execute_query(query)
      end
    end
  end

  module Embedded
    class << self
      def test_path
        File.join(Dir.tmpdir, "neo4j-core-java")
      end

      def stop
        Neo4j::Session.stop if Neo4j::Session.running?
      end

      def clean_start
        raise "Could not stop the current database" unless Neo4j::Session.stop if Neo4j::Session.running?
        # Create a new database
        Neo4j::Session.current = Neo4j::Session.new :embedded
        raise "Could not start embedded database" unless Neo4j::Session.start
        graph_db = Neo4j::Session.current.database
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
        tx.close
      end
    end
  end
end