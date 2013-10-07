require 'rubygems'
require "bundler/setup"
require 'rspec'
require 'fileutils'
require 'tmpdir'
#require 'its'
require 'logger'

#require 'neo4j-server'
#require 'neo4j-embedded'
require 'neo4j-core'
require 'neo4j-wrapper'


Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, "neo4j-core-java")

require "#{File.dirname(__FILE__)}/helpers"

RSpec.configure do |c|
  c.include Helpers
end

# Always use mock db when running db
class Neo4j::Embedded::EmbeddedDatabase
  def self.create_db(location,conf=nil)
    Java::OrgNeo4jTest::TestGraphDatabaseFactory.new.newImpermanentDatabase()
  end
end

RSpec.configure do |c|

  c.before(:each, api: :embedded) do
  end

  c.exclusion_filter = {
      :api => lambda do |ed|
        RUBY_PLATFORM != 'java' && ed == :embedded
      end
  }

end

