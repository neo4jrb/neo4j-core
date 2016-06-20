# To run coverage via travis
require 'coveralls'
Coveralls.wear!
# require 'simplecov'
# SimpleCov.start

# To run it manually via Rake
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start
end

require 'dotenv'
Dotenv.load

require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'fileutils'
require 'tmpdir'
require 'logger'
require 'rspec/its'
require 'neo4j-core'
require 'neo4j-server'
require 'neo4j-embedded' if RUBY_PLATFORM == 'java'
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

require 'neo4j/core/cypher_session'

require 'neo4j/core/cypher_session/adaptors/http'
require 'neo4j/core/cypher_session/adaptors/bolt'
require 'neo4j/core/cypher_session/adaptors/embedded'
module Neo4jSpecHelpers
  def log_queries!
    Neo4j::Server::CypherSession.log_with(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::HTTP.subscribe_to_request(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::Bolt.subscribe_to_request(&method(:puts))
    Neo4j::Core::CypherSession::Adaptors::Embedded.subscribe_to_transaction(&method(:puts))
  end

  def current_transaction
    Neo4j::Transaction.current_for(Neo4j::Session.current)
  end

  # rubocop:disable Style/GlobalVars
  def expect_queries(count)
    start_count = $expect_queries_count
    yield
    expect($expect_queries_count - start_count).to eq(count)
  end

  def setup_query_subscription
    $expect_queries_count = 0

    Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query do |_message|
      $expect_queries_count += 1
    end
  end

  def expect_http_requests(count)
    start_count = $expect_http_request_count
    yield
    expect($expect_http_request_count - start_count).to eq(count)
  end

  def setup_http_request_subscription
    $expect_http_request_count = 0

    Neo4j::Core::CypherSession::Adaptors::HTTP.subscribe_to_request do |_message|
      $expect_http_request_count += 1
    end
  end
  # rubocop:enable Style/GlobalVars
end

# Introduces `let_context` helper method
# This allows us to simplify the case where we want to
# have a context which contains one or more `let` statements
module FixingRSpecHelpers
  # Supports giving either a Hash or a String and a Hash as arguments
  # In both cases the Hash will be used to define `let` statements
  # When a String is specified that becomes the context description
  # If String isn't specified, Hash#inspect becomes the context description
  def let_context(*args, &block)
    context_string, hash =
      case args.map(&:class)
      when [String, Hash] then ["#{args[0]} #{args[1]}", args[1]]
      when [Hash] then [args[0].inspect, args[0]]
      end

    context(context_string) do
      hash.each { |var, value| let(var) { value } }

      instance_eval(&block)
    end
  end

  def subject_should_raise(*args)
    error, message = args
    it_string = "subject should raise #{error}"
    it_string += " (#{message.inspect})" if message

    it it_string do
      expect { subject }.to raise_error error, message
    end
  end

  def subject_should_not_raise(*args)
    error, message = args
    it_string = "subject should not raise #{error}"
    it_string += " (#{message.inspect})" if message

    it it_string do
      expect { subject }.not_to raise_error error, message
    end
  end
end

FileUtils.rm_rf(EMBEDDED_DB_PATH)

RSpec.configure do |config|
  config.include Neo4jSpecHelpers
  config.extend FixingRSpecHelpers

  config.before(:all, api: :server) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_server_session
  end

  config.before(:all, api: :embedded) do
    Neo4j::Session.current.close if Neo4j::Session.current
    create_embedded_session
    Neo4j::Session.current.start unless Neo4j::Session.current.running?
  end

  # if ENV['TEST_AUTHENTICATION'] == 'true'
  #   uri = URI.parse("http://localhost:7474/user/neo4j/password")
  #   db_default = 'neo4j'
  #   suite_default = 'neo4jrb rules, ok?'

  #   config.before(:suite, api: :server) do
  #     Net::HTTP.post_form(uri, { 'password' => db_default, 'new_password' => suite_default })
  #   end

  #   config.after(:suite, api: :server) do
  #     Net::HTTP.post_form(uri, { 'password' => suite_default, 'new_password' => db_default })
  #   end
  # end

  config.before(:each, api: :embedded) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.is_a?(Neo4j::Embedded::EmbeddedSession)
    Neo4j::Session.current || create_embedded_session
    Neo4j::Session.current.start unless Neo4j::Session.current.running?
  end

  config.before(:each, api: :server) do
    curr_session = Neo4j::Session.current
    curr_session.close if curr_session && !curr_session.is_a?(Neo4j::Server::CypherSession)
    Neo4j::Session.current || create_server_session
  end

  config.exclusion_filter = {
    api: lambda do |ed|
      RUBY_PLATFORM != 'java' && ed == :embedded
    end,

    server_only: lambda do |bool|
      RUBY_PLATFORM == 'java' && bool
    end
  }
end
