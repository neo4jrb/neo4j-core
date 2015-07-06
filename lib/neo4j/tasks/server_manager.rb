require 'pathname'

module Neo4j
  module Tasks
    class ServerManager
      BASE_INSTALL_DIR = Pathname.new('db/neo4j')

      def initialize(environment, path)
        @environment = environment || 'development'
        @path = Pathname.new(path)
        FileUtils.mkdir_p(@path)
      end

      # MAIN COMMANDS

      def install(edition_string)
        version = version_from_edition(edition_string)
        puts "Installing neo4j-#{version} (#{@environment} environment)"

        return false if neo4j_binary_path.exist?

        archive_path = download_neo4j(version) unless File.exist?(file_name)
        extract!(archive_path)

        FileUtils.rm archive_path

        puts "Neo4j installed to: #{@path}"
      end

      def start(wait = true)
        puts "Starting Neo4j #{@environment}..."
        system_or_fail(neo4j_command_path(start_argument(wait)))
      end

      def stop
        validate_is_system_admin!

        puts "Stopping Neo4j #{@environment}..."
        system_or_fail(neo4j_command_path(:stop))
      end

      def info
        validate_is_system_admin!

        puts "Info from Neo4j #{@environment}..."
        system_or_fail(neo4j_command_path(:info))
      end

      def restart
        validate_is_system_admin!

        puts "Restarting Neo4j #{@environment}..."
        system_or_fail(neo4j_command_path(:restart))
      end

      def reset
        validate_is_system_admin!

        stop

        FileUtils.rm_rf(@path.join('data/graph.db/*'))
        FileUtils.rm_rf(@path.join('data/log/*'))

        start
      end

      def change_password!
        puts 'This will change the password for a Neo4j server'

        address = prompt_for 'Enter target IP address or host name without protocal and port, press enter for http://localhost:7474'
        target_address = address.empty? ? 'http://localhost:7474' : address

        password = prompt_for 'Input current password. Leave blank if this is a fresh installation of Neo4j.'
        old_password = password.empty? ? 'neo4j' : password

        new_password = prompt_for 'Input new password.'
        fail 'A new password is required' if new_password.blank?

        body = change_password_request(target_address, old_password, new_password)
        if body['errors']
          puts "An error was returned: #{body['errors'][0]['message']}"
        else
          puts 'Password changed successfully! Please update your app to use:'
          puts 'username: neo4j'
          puts "password: #{new_password}"
        end
      end

      def set_auth_enabeled!(enabled)
        value = (!!enabled).to_s
        set_config_properties(
          {
            'dbms.security.authorization_enabled' => value,
            'dbms.security.auth_enabled' => value
            })
      end

      def set_port!(port)
        puts "Config Neo4j #{@environment} for ports #{port} / #{port - 1}"

        set_config_properties({
            'org.neo4j.server.webserver.https.enabled' => false,
            'org.neo4j.server.webserver.port' => port,
            'org.neo4j.server.webserver.https.port' => port - 1
          })
      end

      # END MAIN COMMANDS

      def set_config_properties(properties)
        contents = File.read(property_configuration_path)

        File.open(property_configuration_path, 'w') do |file|
          result = properties.inject(contents) do |result, (property, value)|
            result.gsub(/#{property}\s*=\s*(\w+)/, "#{property}=#{value}")
          end
          file << result
        end
      end

      def self.new_for_os(environment, path)
        manager_class = OS::Underlying.windows? ? WindowsServerManager : StarnixServerManager

        manager_class.new(environment, path)
      end

      protected

      def start_argument(wait)
        wait ? 'start' : 'start-no-wait'
      end

      def binary_command_path(binary_file)
        @path.join('bin', binary_file)
      end

      def neo4j_binary_path
        binary_command_path(neo4j_binary_filename)
      end

      def neo4j_command_path(command)
        neo4j_binary_path.to_s + " #{command}"
      end

      def property_configuration_path
        @path.join('conf', 'neo4j-server.properties')
      end

      def validate_is_system_admin!
        nil
      end

      def system_or_fail(command)
        system(command.to_s) or fail "Unable to run: #{command}" # rubocop:disable Style/AndOr
      end

      def version_from_edition(edition_string)
        edition_string.gsub(/-latest$/) do
          require 'open-uri'
          puts 'Retrieving latest version...'
          latest_version = JSON.parse(open('https://api.github.com/repos/neo4j/neo4j/releases/latest').read)['tag_name']
          puts "Latest version is: #{latest_version}"
          "-#{latest_version}"
        end
      end

      private

      def download_neo4j(version)
        tempfile = Tempfile.open('neo4j-download', encoding: 'ASCII-8BIT')

        url = download_url(version)

        status = HTTParty.head(url).code
        fail "#{version} is not available to download, try a different version" if !(200...300).include?(status)

        tempfile << HTTParty.get(url)
        tempfile.flush

        tempfile.path
      end

      # POSTs to an endpoint with the form required to change a Neo4j password
      # @param [String] target_address The server address, with protocol and port, against which the form should be POSTed
      # @param [String] old_password The existing password for the "neo4j" user account
      # @param [String] new_password The new password you want to use. Shocking, isn't it?
      # @return [Hash] The response from the server indicating success/failure.
      def change_password_request(target_address, old_password, new_password)
        uri = URI.parse("#{target_address}/user/neo4j/password")
        response = Net::HTTP.post_form(uri, 'password' => old_password, 'new_password' => new_password)
        JSON.parse(response.body)
      end

      def prompt_for(prompt)
        puts prompt
        put ' > '
        STDIN.gets.chomp
      end
    end
  end
end