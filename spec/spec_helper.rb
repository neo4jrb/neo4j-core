# To run coverage via travis
require 'simplecov'
require 'coveralls'

SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
  add_filter 'spec'
end

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
require 'neo4j/core'
require 'neo4j/core/query'
require 'ostruct'

if RUBY_PLATFORM == 'java'
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
  # def log_queries!
  #   Neo4j::Server::CypherSession.log_with(&method(:puts))
  #   Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query(&method(:puts))
  #   Neo4j::Core::CypherSession::Adaptors::HTTP.subscribe_to_request(&method(:puts))
  #   Neo4j::Core::CypherSession::Adaptors::Bolt.subscribe_to_request(&method(:puts))
  #   Neo4j::Core::CypherSession::Adaptors::Embedded.subscribe_to_transaction(&method(:puts))
  # end

  def current_transaction
    Neo4j::Transaction.current_for(Neo4j::Session.current)
  end

  class << self
    attr_accessor :expect_queries_count
  end

  # rubocop:disable Style/GlobalVars
  def expect_queries(count)
    start_count = Neo4jSpecHelpers.expect_queries_count
    yield
    expect(Neo4jSpecHelpers.expect_queries_count - start_count).to eq(count)
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

  def delete_schema(session = nil)
    Neo4j::Core::Label.drop_uniqueness_constraints_for(session || current_session)
    Neo4j::Core::Label.drop_indexes_for(session || current_session)
  end

  def create_constraint(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_constraint(property, options)
  end

  def create_index(session, label_name, property, options = {})
    label_object = Neo4j::Core::Label.new(label_name, session)
    label_object.create_index(property, options)
  end

  def test_bolt_url
    ENV['NEO4J_BOLT_URL']
  end

  def test_bolt_adaptor(url, extra_options = {})
    options = {}
    options[:logger_level] = Logger::DEBUG if ENV['DEBUG']

    cert_store = OpenSSL::X509::Store.new
    cert_path = ENV.fetch('TLS_CERTIFICATE_PATH', './db/neo4j/development/certificates/neo4j.cert')
    cert_store.add_file(cert_path)
    options[:ssl] = {cert_store: cert_store}

    Neo4j::Core::CypherSession::Adaptors::Bolt.new(url, options.merge(extra_options))
  end

  def test_http_url
    ENV['NEO4J_URL']
  end

  def test_http_adaptor(url, extra_options = {})
    options = {}
    options[:logger_level] = Logger::DEBUG if ENV['DEBUG']

    Neo4j::Core::CypherSession::Adaptors::Bolt.new(url, options.merge(extra_options))
  end

  def delete_db(session)
    session.query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r')
  end
end

require 'dryspec/helpers'

FileUtils.rm_rf(EMBEDDED_DB_PATH)

RSpec.configure do |config|
  config.include Neo4jSpecHelpers
  config.extend DRYSpec::Helpers
  # config.include Helpers

  config.before(:suite) do
    # for expect_queries method
    Neo4jSpecHelpers.expect_queries_count = 0

    Neo4j::Core::CypherSession::Adaptors::Base.subscribe_to_query do |_message|
      Neo4jSpecHelpers.expect_queries_count += 1
    end
  end

  config.exclusion_filter = {
    api: lambda do |ed|
      RUBY_PLATFORM != 'java' && ed == :embedded
    end,

    server_only: lambda do |bool|
      RUBY_PLATFORM == 'java' && bool
    end,

    bolt: lambda do
      ENV['NEO4J_VERSION'].to_s.match(/^(community|enterprise)-2\./) ||
        RUBY_ENGINE == 'jruby' # Because jruby doesn't implement sendmsg.  Hopefully we can figure this out
    end
  }
end
