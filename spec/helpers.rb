require "tmpdir"
load "Rakefile"

module Helpers
  class << self
    def start_server_banner(server_type)
      puts
      puts '#'*26
      puts "Started #{server_type} Server"
      puts '#'*26
    end
  end

  module Rest
    class << self
      def stop
        Rake.application['neo4j:stop'].invoke
        %x[another_neo4j/bin/neo4j stop]
        Neo4j::Session.stop
      end

      def clean_start
        if @started_server.nil?
          @started_server = true
          at_exit { stop }
          Rake.application['neo4j:reset'].invoke
          %x[another_neo4j/bin/neo4j start]
          sleep(1) # give the server some time to breath otherwise it doesn't respond
          Helpers.start_server_banner("REST")
        end
        Neo4j::Session.stop if Neo4j::Session.running?
        Neo4j::Session.new :rest
        query = <<-EOQ
        START n = node(*)
        MATCH n-[r?]-()
        WHERE ID(n) > 0
        DELETE n, r
        EOQ
        Neo4j::Session.current.neo.execute_query(query)
      end
    end
  end

  module Embedded
    class << self
      def test_path
        File.join(Dir.tmpdir, "neo4j-core-java-#{rand}")
      end

      def stop
        if Neo4j::Session.running?
          Neo4j::Session.stop 
        else
          true
        end
      end

      def clean_start
        raise "Could not stop the current database: #{Neo4j::Session.running?}" unless stop
        # Create a new database
        Neo4j::Session.new :embedded, test_path
        raise "Could not start embedded database" unless Neo4j::Session.start
        Helpers.start_server_banner("Embedded")
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