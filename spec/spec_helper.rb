# To run coverage via travis
require 'coveralls'
Coveralls.wear!

# To run it manually via Rake
if ENV['COVERAGE']
  puts "RUN SIMPLECOV"
  require 'simplecov'
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start
end

require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'logger'
require 'rspec/its'
require 'neo4j-core'
require 'ostruct'


if RUBY_PLATFORM == 'java'
  require "neo4j-embedded/embedded_impermanent_session"

  # for some reason this is not impl. in JRuby
  class OpenStruct
    def [](key)
      self.send(key)
    end
  end
end

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, "neo4j-core-java")

require "#{File.dirname(__FILE__)}/helpers"

RSpec.configure do |c|
  c.include Helpers
end

def create_embedded_session
  Neo4j::Session.open(:impermanent_db, EMBEDDED_DB_PATH, auto_commit: true)
end

def create_server_session
  Neo4j::Session.open(:server_db, "http://localhost:7474")
end

def create_named_server_session(name, default = nil)
  Neo4j::Session.open_named(:server_db, name, default, "http://localhost:7474")
end

def session
  Neo4j::Session.current
end


def unique_random_number
  "#{Time.now.year}#{Time.now.to_i}#{Time.now.usec.to_s[0..2]}".to_i
end

FileUtils.rm_rf(EMBEDDED_DB_PATH)

RSpec.configure do |c|

  c.before(:all, api: :server) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_server_session
  end

  c.before(:all, api: :embedded) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_embedded_session
    Neo4j::Session.current.start unless Neo4j::Session.current.running?
  end

  c.before(:each, api: :embedded) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.kind_of?(Neo4j::Embedded::EmbeddedSession)
    Neo4j::Session.current || create_embedded_session
    Neo4j::Session.current.start unless Neo4j::Session.current.running?
  end

  c.before(:each, api: :server) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.kind_of?(Neo4j::Server::CypherSession)
    Neo4j::Session.current || create_server_session
  end

  #c.after(:all, api: :server) do
  #  clean_server_db if Neo4j::Session.current && Neo4j::Session.current.kind_of?(Neo4j::Server::CypherSession)
  #end

  c.exclusion_filter = {
      :api => lambda do |ed|
        RUBY_PLATFORM != 'java' && ed == :embedded
      end
  }

end

