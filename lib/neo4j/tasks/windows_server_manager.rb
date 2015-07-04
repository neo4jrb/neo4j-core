require File.expand_path('../server_manager', __FILE__)

module Neo4j
  module Tasks
    class WindowsServerManager < ServerManager

      def neo4j_binary
        'Neo4j.bat'
      end

      def start_command(wait)
        binary_file = neo4j_binary

        if local_service?
          binary_file += " #{start_argument(wait)}"
        else
          puts 'Starting Neo4j directly, not as a service.'
        end

        binary_file
      end

      def local_service?
        system_or_fail('reg query "HKU\\S-1-5-19"').size > 0
      end

      def validate_is_system_admin!
        return if nt_admin?

        fail 'You do not have administrative rights to stop the Neo4j Service'
      end

      private

      def nt_admin?
        system_or_fail('reg query "HKU\\S-1-5-19"').size > 0
      end

    end
  end
end