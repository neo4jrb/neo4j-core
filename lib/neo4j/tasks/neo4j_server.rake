# :nocov:
# borrowed from architect4r
require 'os'
require 'httparty'
require 'zip'
require 'httparty'
require 'pathname'
require File.expand_path('../config_server', __FILE__)
require File.expand_path('../windows_server_manager', __FILE__)
require File.expand_path('../starnix_server_manager', __FILE__)


namespace :neo4j do
  def file_name
    OS::Underlying.windows? ? 'neo4j.zip' : 'neo4j-unix.tar.gz'
  end

  def download_url(edition)
    "http://dist.neo4j.org/neo4j-#{edition}-#{OS::Underlying.windows? ? 'windows.zip' : 'unix.tar.gz'}"
  end

  def download_neo4j(edition)
    success = false

    File.open(file_name, 'wb') do |file|
      file << request_url(download_url(edition))
      success = true
    end

    file_name
  ensure
    File.delete(file_name) unless success
  end

  def request_url(url)
    status = HTTParty.head(url).code
    fail "#{edition} is not available to download, try a different version" if status < 200 || status >= 300

    HTTParty.get(url)
  end

  def get_environment(args)
    args[:environment] || 'development'
  end

  BASE_INSTALL_DIR = Pathname.new('db/neo4j')

  def install_location!(args)
    FileUtils.mkdir_p(BASE_INSTALL_DIR)

    BASE_INSTALL_DIR.join(get_environment(args))
  end

  def config_location(args)
    install_location!(args).join('conf/neo4j-server.properties')
  end

  def system_or_fail(command)
    system(command.to_s) or fail "Unable to run: #{command}" # rubocop:disable Style/AndOr
  end

  def get_edition(args)
    edition_string = args[:edition]

    edition_string.gsub(/-latest$/) do
      require 'open-uri'
      puts 'Retrieving latest version...'
      latest_version = JSON.parse(open('https://api.github.com/repos/neo4j/neo4j/releases/latest').read)['tag_name']
      puts "Latest version is: #{latest_version}"
      "-#{latest_version}"
    end
  end

  def nt_admin?
    system_or_fail('reg query "HKU\\S-1-5-19"').size > 0
  end

  def server_manager(environment)
    ::Neo4j::Tasks::ServerManager.new_for_os(environment)
  end

  desc 'Install Neo4j with auth disabled in v2.2+, example neo4j:install[community-latest,development]'
  task :install, :edition, :environment do |_, args|
    edition = get_edition(args)
    environment = get_environment(args)
    puts "Installing Neo4j-#{edition} environment: #{environment}"

    downloaded_file = download_neo4j(edition) unless File.exist?(file_name)

    if OS::Underlying.windows?
      # Extract and move to neo4j directory
      unless install_location!(args).exist?
        Zip::ZipFile.open(downloaded_file) do |zip_file|
          zip_file.each do |f|
            f_path = File.join('.', f.name)
            FileUtils.mkdir_p(File.dirname(f_path))
            begin
              zip_file.extract(f, f_path) unless File.exist?(f_path)
            rescue
              puts "#{f.name} failed to extract."
            end
          end
        end
        FileUtils.mv "neo4j-#{edition}", install_location!(args)
        FileUtils.rm downloaded_file
      end

      # Install if running with Admin Privileges
      if nt_admin?
        bin_path = install_location!(args).join('bin/neo4j')
        system_or_fail("\"#{bin_path} install\"")
        puts 'Neo4j Installed as a service.'
      end

    else
      system_or_fail("tar -xvf #{downloaded_file}")
      system_or_fail("mv neo4j-#{edition} #{install_location!(args)}")
      system_or_fail("rm #{downloaded_file}")
      puts 'Neo4j Installed in to neo4j directory.'
    end
    rake_auth_toggle(args, :disable) unless /-2\.0|1\.[0-9]/.match(args[:edition])
    puts "Type 'rake neo4j:start' or 'rake neo4j:start[ENVIRONMENT]' to start it\nType 'neo4j:config[ENVIRONMENT,PORT]' for changing server port, (default 7474)"
  end

  desc 'Start the Neo4j Server'
  task :start, :environment do |_, args|
    server_manager = server_manager(args[:environment])
    server_manager.start
  end

  desc 'Start the Neo4j Server asynchronously'
  task :start_no_wait, :environment do |_, args|
    server_manager = server_manager(args[:environment])
    server_manager.start(false)
  end

  desc 'Configure Server, e.g. rake neo4j:config[development,8888]'
  task :config, :environment, :port do |_, args|
    port = args[:port]
    fail 'no port given' unless port
    puts "Config Neo4j #{get_environment(args)} for ports #{port} / #{port.to_i - 1}"
    location = config_location(args)
    replace = Neo4j::Tasks::ConfigServer.config(location.read, port)
    location.open('w') { |file| file.puts replace }
  end

  def validate_is_system_admin!
    return unless OS::Underlying.windows?
    return if nt_admin?

    fail 'You do not have administrative rights to stop the Neo4j Service'
  end

  def run_neo4j_command_or_fail!(args, command)
    binary = OS::Underlying.windows? ? 'Neo4j.bat' : 'neo4j'

    system_or_fail(install_location!(args).join("bin/#{binary} #{command}"))
  end

  desc 'Stop the Neo4j Server'
  task :stop, :environment do |_, args|
    server_manager = server_manager(args[:environment])
    server_manager.stop
  end

  desc 'Get info the Neo4j Server'
  task :info, :environment do |_, args|
    server_manager = server_manager(args[:environment])
    server_manager.info
  end

  desc 'Restart the Neo4j Server'
  task :restart, :environment do |_, args|
    server_manager = server_manager(args[:environment])
    server_manager.restart
  end

  desc 'Reset the Neo4j Server'
  task :reset_yes_i_am_sure, :environment do |_, args|
    validate_is_system_admin!

    run_neo4j_command_or_fail!(args, :stop)

    # Reset the database
    database_dir = install_location!(args).join('data/graph.db')
    FileUtils.rm_rf(database_dir)
    FileUtils.mkdir(database_dir)

    # Remove log files
    log_dir = install_location!(args).join('data/log')
    FileUtils.rm_rf(log_dir)
    FileUtils.mkdir(log_dir)

    run_neo4j_command_or_fail!(args, :start)
  end

  def prompt_for(prompt)
    puts prompt
    put ' > '
    STDIN.gets.chomp
  end

  desc 'Neo4j 2.2: Change connection password'
  task :change_password do
    puts 'This will change the password for a Neo4j server'

    address = prompt_for 'Enter target IP address or host name without protocal and port, press enter for http://localhost:7474'
    target_address = address.empty? ? 'http://localhost:7474' : address

    password = prompt_for 'Input current password. Leave blank if this is a fresh installation of Neo4j.'
    old_password = password.empty? ? 'neo4j' : password

    new_password = prompt_for 'Input new password.'
    fail 'A new password is required' if new_password.empty?

    body = Neo4j::Tasks::ConfigServer.change_password(target_address, old_password, new_password)
    if body['errors']
      puts "An error was returned: #{body['errors'][0]['message']}"
    else
      puts 'Password changed successfully! Please update your app to use:'
      puts 'username: neo4j'
      puts "password: #{new_password}"
    end
  end

  def rake_auth_toggle(args, status)
    location = config_location(args)
    replace = Neo4j::Tasks::ConfigServer.toggle_auth(status, location.read)
    location.open('w') { |file| file.puts replace }
  end

  def auth_toggle_complete(status)
    puts "Neo4j basic authentication #{status}. Restart server to apply."
  end

  desc 'Neo4j 2.2: Enable Auth'
  task :enable_auth, :environment do |_, args|
    rake_auth_toggle(args, :enable)
    auth_toggle_complete('enabled')
  end

  desc 'Neo4j 2.2: Disable Auth'
  task :disable_auth, :environment do |_, args|
    rake_auth_toggle(args, :disable)
    auth_toggle_complete('disabled')
  end
end
