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
  desc "Validity modules"
  task :validity do
    spec_files = Dir["spec/*.rb"].map do |sf|
      case sf
      when "spec/helpers.rb", "spec/spec_helper.rb"
        nil
      else
        sf
      end
    end.join(' ').strip
    success = system("rspec #{spec_files}")
    abort("RSpec neo4j-core for abstract module implementation failed") unless success
  end

  desc "Run specific validity features"
  namespace :validity do
    desc "Run validity specs for Session"
    task :session do
      success = system('rspec spec/session_spec.rb')
      abort("Session validity specs failed") unless success
    end

    desc "Run validity specs for Node"
    task :node do
      success = system('rspec spec/node_spec.rb')
      abort("Node validity specs failed") unless success
    end

    desc "Run validity specs for Label"
    task :label do
      success = system('rspec spec/label_spec.rb')
      abort("Label validity specs failed") unless success
    end
  end

  desc "REST implementation"
  task :rest do
    success = system('rspec spec/rest')
    abort("RSpec neo4j-core for REST implementation failed") unless success
  end

  desc "Run specific REST features"
  namespace :rest do
    desc "Run REST specs for Session"
    task :session do
      success = system('rspec spec/rest/session_spec.rb')
      abort("REST Session specs failed") unless success
    end

    desc "Run REST specs for Node"
    task :node do
      success = system('rspec spec/rest/node_spec.rb')
      abort("REST Node specs failed") unless success
    end

    desc "Run REST specs for Label"
    task :label do
      success = system('rspec spec/rest/label_spec.rb')
      abort("REST Label specs failed") unless success
    end
  end

  desc "Embedded implementation"
  task :embedded do
    success = system('rspec spec/embedded')
    abort("RSpec neo4j-core for embedded implementation failed") unless success
  end

  desc "Run specific Embedded features"
  namespace :embedded do
    desc "Run Embedded specs for Session"
    task :session do
      success = system('rspec spec/embedded/session_spec.rb')
      abort("Embedded Session specs failed") unless success
    end

    desc "Run Embedded specs for Node"
    task :node do
      success = system('rspec spec/embedded/node_spec.rb')
      abort("Embedded Node specs failed") unless success
    end

    desc "Run Embedded specs for Label"
    task :label do
      success = system('rspec spec/embedded/label_spec.rb')
      abort("Embedded Label specs failed") unless success
    end
  end
end

desc "Run all the neo4j-core specs"
task test: ['test:abstract', 'test:rest', 'test:embedded']

desc "Run all the Session specs"
task session: ['rest:session', 'embedded:session']

desc "Run all the Node specs"
task node: ['rest:node', 'embedded:node']

desc "Run all the Session specs"
task label: ['rest:label', 'embedded:label']

desc "Clean the server database"
task :clean => ['neo4j:stop', 'neo4j:reset']

desc "Default task - testing"
task :default => [:test]
