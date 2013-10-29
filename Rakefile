require 'rake'
require "bundler/gem_tasks"
require 'neo4j/tasks'

def jar_path
  spec = Gem::Specification.find_by_name("neo4j-community")
  gem_root = spec.gem_dir
  gem_root + "/lib/neo4j-community/jars"
end

desc "Run neo4j-core specs"
task 'spec-core' do
  success = system('rspec spec/neo4j-server spec/neo4j-embedded')
  abort("RSpec neo4j-core failed") unless success
end

desc "Run neo4j-wrapper specs"
task :'spec-wrapper' do
  success = system('rspec spec/neo4j-wrapper')
  abort("RSpec neo4j-wrapper failed") unless success
end
#RSpec::Core::RakeTask.new("spec-wrapper") do |t|
#  #t.rspec_opts = ["-c"]
#  t.rspec_opts = './spec/neo4j-wrapper'
#end

desc 'delete server db'
task :rm_server_db do
  FileUtils.rm_rf('./neo4j/data')
  FileUtils.mkdir_p('./neo4j/data')
end

task :clean_db => ['neo4j:stop', 'rm_server_db', 'neo4j:start']

task :default => ['spec-core', 'neo4j:restart', 'spec-wrapper']