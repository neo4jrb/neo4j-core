require 'rake'
#require 'rcov/rcovtask'
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'neo4j/tasks'

def jar_path
  spec = Gem::Specification.find_by_name("neo4j-community")
  gem_root = spec.gem_dir
  gem_root + "/lib/neo4j-community/jars"
end

desc "Run all specs"
RSpec::Core::RakeTask.new("spec") do |t|
  t.rspec_opts = ["-c"]
end

desc "Compile neo4jrb-adaptor.jar"
task 'build-java' do
  sh <<-END
    rm -rf target
    rm lib/neo4j-core/jars/neo4jrb-adaptor.jar
    mkdir target
    javac -d target -classpath $(echo #{jar_path}/*.jar | tr ' ' ':') java/neo4j/rb/Adaptor.java
    jar cvf lib/neo4j-core/jars/neo4jrb-adaptor.jar -C target neo4j
    rm -rf target
  END
end

task 'download_and_start_server' do
    Rake::Task["neo4j:install"].invoke('community', '2.0.0-M06')
    Rake::Task['neo4j:start']
    puts "Sleep 30 sec to make sure server starts"
    sleep(30) # just in case
    puts "Server should now be awake"
end

task 'travis' => [:download_and_start_server, :spec]

task :default => 'spec'