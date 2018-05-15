require 'rake'
require 'bundler/gem_tasks'
require 'neo4j/rake_tasks'
require 'yard'

load './spec/lib/yard_rspec.rb'

def jar_path
  spec = Gem::Specification.find_by_name('neo4j-community')
  gem_root = spec.gem_dir
  gem_root + '/lib/neo4j-community/jars'
end

YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', 'spec/**/*_spec.rb']
end

desc 'Run neo4j-core specs'
task 'spec' do
  success = system('rspec spec')
  abort('RSpec neo4j-core failed') unless success
end

desc 'Generate coverage report'
task 'coverage' do
  ENV['COVERAGE'] = 'true'
  rm_rf 'coverage/'
  task = Rake::Task['spec']
  task.reenable
  task.invoke
end

task default: [:spec]

CHARS = ('0'..'z').to_a
def string
  Array.new(rand(1_000)) { CHARS.sample }.join
end

MAX_NUM = 10_00 * 999_999
HALF_MAX_NUM = MAX_NUM.fdiv(2)
def int
  rand(MAX_NUM)
end

def float
  (rand * MAX_NUM) - HALF_MAX_NUM
end

DIFFERENT_QUERIES = [
  ['MATCH (n) RETURN n LIMIT {limit}', -> { {limit: rand(20)} }],
  ['MATCH (n) WITH n LIMIT {limit} DELETE n', -> { {limit: rand(5)} }],
  ['MATCH (n) SET n.some_prop = {value}', -> { {value: send(%i[string float int].sample)} }],
  ['CREATE (n:Report) SET n = {props} RETURN n', -> { {props: {a_string: string, a_int: int, a_float: float}} }]
]

task :stress_test, [:times, :local] do |_task, args|
  require 'logger'
  require 'neo4j/core'
  require 'neo4j/core/cypher_session/adaptors/bolt'
  system('rm stress_test.log')

  if args[:local] == 'true'
    cert_store = OpenSSL::X509::Store.new.tap { |store| store.add_file('./tmp/certificates/neo4j.cert') }
    ssl_options = {cert_store: cert_store}
    url = 'bolt://neo4j:neo5j@localhost:7687'
  else
    url = 'bolt://neo4j:y7_mAQaA0RG3pqOmAAVs0hvas_XJWgAG38WOdPWGJ9o@b40527a0.databases.neo4j.io'
    ssl_options = {}
  end

  # logger_options = {}
  logger_options = {logger_location: 'stress_test.log', logger_level: Logger::DEBUG}

  bolt_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new(url, {timeout: 10, ssl: ssl_options}.merge(logger_options))

  neo4j_session = Neo4j::Core::CypherSession.new(bolt_adaptor)

  i = 0
  start = Time.now
  args.fetch(:times, 100).to_i.times do
    # putc '.'

    begin
      query, params = DIFFERENT_QUERIES.sample
      params = params.call if params.respond_to?(:call)
      params ||= {}
      neo4j_session.query(query, params).to_a.inspect
    rescue => e # rubocop:disable Lint/RescueWithoutErrorClass
      raise e
    end

    i += 1
    puts "#{i.fdiv(Time.now - start)} i/s" if (i % 20).zero?
  end

  puts 'Done!'
end

# require 'coveralls/rake/task'
# Coveralls::RakeTask.new
# task :test_with_coveralls => [:spec, 'coveralls:push']
#
# task :default => ['test_with_coveralls']
