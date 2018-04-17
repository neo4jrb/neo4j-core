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

big_string = 'a' * 100_000
big_int = 100_000 * 123456
big_float = big_int + 0.1359162596523621956

DIFFERENT_QUERIES = [
  ['MATCH (n) RETURN n LIMIT {limit}', {limit: 20}],
  ['MATCH (n) DELETE n'],
  ['CREATE (n:Report) SET n = {props} RETURN n', {props: {big_string: big_string, big_int: big_int, big_float: big_float}}]
]

task :stress_test do
  require 'neo4j-core'
  require 'neo4j/core/cypher_session/adaptors/bolt'
  system('rm stress_test.log')
  bolt_adaptor = Neo4j::Core::CypherSession::Adaptors::Bolt.new('bolt://neo4j:neo5j@localhost:7687', timeout: 10, logger_location: 'stress_test.log', logger_level: Logger::DEBUG)

  neo4j_session = Neo4j::Core::CypherSession.new(bolt_adaptor)

  2.times do
    putc '.'
    begin
      neo4j_session.query(*DIFFERENT_QUERIES.sample).to_a.inspect
    rescue => e
      raise e
    end
  end

  puts 'Done!'
end

# require 'coveralls/rake/task'
# Coveralls::RakeTask.new
# task :test_with_coveralls => [:spec, 'coveralls:push']
#
# task :default => ['test_with_coveralls']
