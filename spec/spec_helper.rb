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
  Neo4j::Config[:debug_java] = true
  EMBEDDED_DB_PATH = File.join(Dir.tmpdir, "neo4j-core-rspec-db2")

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


  RSpec.configure do |c|
    c.filter_run_excluding :slow => ENV['TRAVIS'] != 'true'

    c.before(:all, :type => :integration) do
      Neo4j::Config[:storage_path] = File.join(Dir.tmpdir, "neo4j_core_integration_rspecs")
      FileUtils.rm_rf Neo4j::Config[:storage_path]
    end

    c.after(:each, :type => :integration) do
      finish_tx
    end

    c.before(:each, :type => :mock_db) do
      Neo4j.shutdown
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
  end

end unless @_neo4j_rspec_loaded