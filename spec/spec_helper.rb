# To run coverage via travis
require 'coveralls'
Coveralls.wear!
# require 'simplecov'
# SimpleCov.start

# To run it manually via Rake
if ENV['COVERAGE']
  puts 'RUN SIMPLECOV'
  require 'simplecov'
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start
end

require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'logger'
require 'rspec/its'
require 'neo4j-core'
require 'ostruct'

if RUBY_PLATFORM == 'java'
  require 'neo4j-embedded/embedded_impermanent_session'
  require 'ruby-debug'

  # for some reason this is not impl. in JRuby
  class OpenStruct
    def [](key)
      send(key)
    end
  end
end

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, 'neo4j-core-java')

require "#{File.dirname(__FILE__)}/helpers"

RSpec.configure do |c|
  c.include Helpers
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

  # if ENV['TEST_AUTHENTICATION'] == 'true'
  #   uri = URI.parse("http://localhost:7474/user/neo4j/password")
  #   db_default = 'neo4j'
  #   suite_default = 'neo4jrb rules, ok?'

  #   c.before(:suite, api: :server) do
  #     Net::HTTP.post_form(uri, { 'password' => db_default, 'new_password' => suite_default })
  #   end

  #   c.after(:suite, api: :server) do
  #     Net::HTTP.post_form(uri, { 'password' => suite_default, 'new_password' => db_default })
  #   end
  # end

  c.before(:each, api: :embedded) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.is_a?(Neo4j::Embedded::EmbeddedSession)
    Neo4j::Session.current || create_embedded_session
    Neo4j::Session.current.start unless Neo4j::Session.current.running?
  end

  c.before(:each, api: :server) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.is_a?(Neo4j::Server::CypherSession)
    Neo4j::Session.current || create_server_session
  end

  c.exclusion_filter = {
    api: lambda do |ed|
      RUBY_PLATFORM != 'java' && ed == :embedded
    end
  }

end
