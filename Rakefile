require 'rake'
require "bundler/gem_tasks"
require 'neo4j/tasks/neo4j_server'
require 'yard'

load './spec/lib/yard_rspec.rb'

def jar_path
  spec = Gem::Specification.find_by_name("neo4j-community")
  gem_root = spec.gem_dir
  gem_root + "/lib/neo4j-community/jars"
end

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'spec/**/*_spec.rb']   # optional
#  t.options = ['--debug'] # optional
end

desc "Run neo4j-core specs"
task 'spec-core' do
  success = system('rspec spec')
  abort("RSpec neo4j-core failed") unless success
end


task :default => ['spec-core']
