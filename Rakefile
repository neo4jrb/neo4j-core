require 'rake'
require "bundler/gem_tasks"
require 'tasks'

def jar_path
  spec = Gem::Specification.find_by_name("neo4j-community")
  gem_root = spec.gem_dir
  gem_root + "/lib/neo4j-community/jars"
end

desc "Run neo4j-core specs"
namespace :test do
  desc "REST implementation"
  task :rest do
    success = system('rspec spec/rest')
    abort("RSpec neo4j-core for REST implementation failed") unless success
  end

  desc "Embedded implementation"
  task :embedded do
    success = system('rspec spec/embedded')
    abort("RSpec neo4j-core for embedded implementation failed") unless success
  end
end

desc "Run all the neo4j-core specs"
task test: ['test:rest', 'test:embedded']

task :clean => ['neo4j:stop', 'neo4j:reset']
task :default => [:test]
