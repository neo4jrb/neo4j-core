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


require "#{File.dirname(__FILE__)}/helpers"

RSpec.configure do |c|
  c.include Helpers
end


RSpec.configure do |c|

  c.before(:each, api: :embedded) do
    Neo4j::Embedded::EmbeddedDatabase.stub(:create_db) do
      Java::OrgNeo4jTest::TestGraphDatabaseFactory.new.newImpermanentDatabase()
    end
  end

  c.exclusion_filter = {
      :api => lambda do |ed|
        RUBY_PLATFORM != 'java' && ed == :embedded
      end
  }

end

