require 'pathname'

puts 'server manager!'

module Neo4j
  module Tasks
    class ServerManager
      BASE_INSTALL_DIR = Pathname.new('db/neo4j')

      def initialize(environment)
        @environment = environment || 'development'
      end

      # MAIN COMMANDS

      def start(wait = true)
        puts "Starting Neo4j #{@environment}..."
        system_or_fail(binary_command(start_command(wait)))
      end

      def stop
        validate_is_system_admin!

        puts "Stopping Neo4j #{@environment}..."
        run_neo4j_command_or_fail!(:stop)
      end

      def info
        validate_is_system_admin!

        puts "Info from Neo4j #{@environment}..."
        run_neo4j_command_or_fail!(:info)
      end

      def restart
        validate_is_system_admin!

        puts "Restarting Neo4j #{@environment}..."
        run_neo4j_command_or_fail!(:restart)
      end

      # END MAIN COMMANDS

      def self.new_for_os(environment)
        manager_class = OS::Underlying.windows? ? WindowsServerManager : StarnixServerManager

        manager_class.new(environment)
      end

      protected

      def start_argument(wait)
        wait ? 'start' : 'start-no-wait'
      end

      def binary_command(binary_file)
        install_location!.join('bin', binary_file)
      end

      def validate_is_system_admin!
        nil
      end

      def system_or_fail(command)
        system(command.to_s) or fail "Unable to run: #{command}" # rubocop:disable Style/AndOr
      end

      private

      def run_neo4j_command_or_fail!(command)
        system_or_fail(binary_command("#{neo4j_binary} #{command}"))
      end

      def install_location!
        FileUtils.mkdir_p(BASE_INSTALL_DIR)

        BASE_INSTALL_DIR.join(@environment)
      end

    end
  end
end