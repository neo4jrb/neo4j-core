require File.expand_path('../server_manager', __FILE__)

module Neo4j
  module Tasks
    class StarnixServerManager < ServerManager

      def neo4j_binary
        'neo4j'
      end

      def start_command(wait)
        "#{neo4j_binary} #{start_argument(wait)}"
      end
    end
  end
end