require File.expand_path("../config_server", __FILE__)

namespace :neo4j do
  def default_password
    'neo4j'
  end

  def test_password
    'neo4jrb rules, ok?'
  end

  task :set_test_password, :environment do |_, args|
    Neo4j::Tasks::ConfigServer.change_password('http://localhost:7474', default_password, test_password)
    puts "Database password set: `#{test_password}`"
  end

  task :reset_default_password, :environment do |_, args|
    Neo4j::Tasks::ConfigServer.change_password('http://localhost:7474', test_password, default_password)
    puts "Database password reset to default: `#{default_password}`"
  end
end
