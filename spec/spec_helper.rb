require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'its'
require 'logger'

require 'neo4j-core'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }


#unless ENV['TRAVIS'] == 'true'
#  puts "Use test db"
#  Neo4j::Community.load_test_jars!
#  #Neo4j::Core::Database.default_embedded_db = Java::OrgNeo4jTest::ImpermanentGraphDatabase
#  $NEO4J_SERVER = Java::OrgNeo4jTest::ImpermanentGraphDatabase.new
#end

# Config
Neo4j::Config[:logger_level] = Logger::ERROR
Neo4j::Config[:debug_java] = true
EMBEDDED_DB_PATH = File.join(Dir.tmpdir, "neo4j-core-java")
FileUtils.rm_rf EMBEDDED_DB_PATH

def embedded_db
  @@db ||= begin
    FileUtils.rm_rf EMBEDDED_DB_PATH
    db = Java::OrgNeo4jKernel::EmbeddedGraphDatabase.new(EMBEDDED_DB_PATH, Neo4j.config.to_java_map)
    at_exit do
      db.shutdown
      FileUtils.rm_rf EMBEDDED_DB_PATH
    end
    db
  end
end

def new_java_tx(db)
  finish_tx if @tx
  @tx = db.begin_tx
end

def finish_tx
  return unless @tx
  @tx.success
  @tx.finish
  @tx = nil
end

def new_tx
  finish_tx if @tx
  @tx = Neo4j::Transaction.new
end

Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j_core_integration_rspec")
FileUtils.rm_rf Neo4j::Config[:storage_path]

RSpec.configure do |c|
  c.filter_run_excluding :slow => ENV['TRAVIS'] != 'true'

  c.include(CustomNeo4jMatchers)

  #c.before(:all, :type => :java_integration) do
  #  finish_tx
  #  Neo4j.shutdown
  #  FileUtils.rm_rf Neo4j::Config[:storage_path]
  #end

  c.after(:each, :type => :integration) do
    finish_tx
  end

  c.before(:all, :type => :mock_db) do
    Neo4j.shutdown
    Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j_core_integration_rspec")
    FileUtils.rm_rf Neo4j::Config[:storage_path]
    Neo4j::Core::Database.default_embedded_db= MockDb
    Neo4j.start
  end

  c.after(:all, :type => :mock_db) do
    Neo4j.shutdown
    Neo4j::Core::Database.default_embedded_db = nil
  end
end
