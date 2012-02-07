begin
  # make sure that this file is not loaded twice
  @_neo4j_rspec_loaded = true

  require 'rubygems'
  require "bundler/setup"
  require 'rspec'
  require 'fileutils'
  require 'tmpdir'
  require 'its'
  require 'logger'

  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), "..", "lib")
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
  Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j-core-rspec-db")
  Neo4j::Config[:debug_java] = true

  # Util
  def rm_db_storage
    FileUtils.rm_rf Neo4j::Config[:storage_path]
    raise "Can't delete db" if File.exist?(Neo4j::Config[:storage_path])
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


  RSpec.configure do |c|
    $name_counter = 0
    c.filter_run_excluding :slow => ENV['TRAVIS'] != 'true'

    c.before(:each, :type => :transactional) do
      new_tx
    end

    c.after(:each, :type => :transactional) do
      finish_tx
    end

    c.before(:each, :type => :mock_db) do
      @mock_db = MockDb.new
      @mock_db_class = double("JavaGraphDbClass")
      @mock_db_class.stub!(:new) { |*| @mock_db }
      Neo4j::Core::Database.default_embedded_db= @mock_db_class
    end

    c.after(:each, :type => :mock_db) do
      Neo4j.shutdown
      Neo4j::Core::Database.default_embedded_db = nil
      @mock_db = nil
      @mock_db_class = nil
    end

    c.after(:each, :type => :java_integration) do
    end

    c.before(:all, :type => :java_integration) do
      rm_db_storage #unless Neo4j.running?
    end

  end

end unless @_neo4j_rspec_loaded