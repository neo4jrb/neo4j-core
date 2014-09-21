require 'rake'
require "bundler/gem_tasks"
require 'yard'

load './spec/lib/yard_rspec.rb'

def jar_path
  spec = Gem::Specification.find_by_name("neo4j-community")
  gem_root = spec.gem_dir
  gem_root + "/lib/neo4j-community/jars"
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'spec/**/*_spec.rb']
end

desc "Run neo4j-core specs"
task 'spec' do
  success = system('rspec spec')
  abort("RSpec neo4j-core failed") unless success
end

desc 'Generate coverage report'
task 'coverage' do
  ENV['COVERAGE'] = 'true'
  rm_rf "coverage/"
  task = Rake::Task['spec']
  task.reenable
  task.invoke
end

task :default => [:spec]

# require 'coveralls/rake/task'
# Coveralls::RakeTask.new
# task :test_with_coveralls => [:spec, 'coveralls:push']
#
# task :default => ['test_with_coveralls']
