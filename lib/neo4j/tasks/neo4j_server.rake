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
  BASE_INSTALL_DIR = Pathname.new('db/neo4j')

  def server_path(environment)
    BASE_INSTALL_DIR.join((environment || :development).to_s)
  end

  def server_manager(environment, path)
    ::Neo4j::Tasks::ServerManager.new_for_os(environment, path)
  end

  desc 'Install Neo4j with auth disabled in v2.2+, example neo4j:install[community-latest,development]'
  task :install, :edition, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.install(args[:edition])
    server_manage.set_auth_enabeled!(false) unless /-2\.0|1\.[0-9]/.match(args[:edition])

    puts "Type 'rake neo4j:start' or 'rake neo4j:start[ENVIRONMENT]' to start it"
    puts "Type 'neo4j:config[ENVIRONMENT,PORT]' for changing server port, (default 7474)"
  end

  desc 'Start the Neo4j Server'
  task :start, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.start
  end

  desc 'Start the Neo4j Server asynchronously'
  task :start_no_wait, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.start(false)
  end

  desc 'Configure Server, e.g. rake neo4j:config[development,8888]'
  task :config, :environment, :port do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.set_port!(args[:port].to_i)
  end

  desc 'Stop the Neo4j Server'
  task :stop, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.stop
  end

  desc 'Get info the Neo4j Server'
  task :info, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.info
  end

  desc 'Restart the Neo4j Server'
  task :restart, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.restart
  end

  desc 'Reset the Neo4j Server'
  task :reset_yes_i_am_sure, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.reset
  end

  desc 'Neo4j 2.2: Change connection password'
  task :change_password do
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.change_password!
  end

  desc 'Neo4j 2.2: Enable Auth'
  task :enable_auth, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.set_auth_enabeled!(true)

    puts "Neo4j basic authentication enabled. Restart server to apply."
  end

  desc 'Neo4j 2.2: Disable Auth'
  task :disable_auth, :environment do |_, args|
    server_manager = server_manager(args[:environment], server_path(args[:environment]))
    server_manager.set_auth_enabeled!(false)

    puts "Neo4j basic authentication disabled. Restart server to apply."
  end
end
