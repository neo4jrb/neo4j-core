require "neo4j-core/session"
require "neo4j-core/node"
require "neo4j-core/node/rest"
require "neo4j-core/label"
require "neo4j-core/relationship"
require "neo4j-core/relationship/rest"

# If the platform is Java then load all java related files
if RUBY_PLATFORM == 'java'
  require "java"
  Dir["#{Dir.pwd}/lib/neo4j-core/jars/*.jar"].each do |jar|
    jar = File.basename(jar)
    require "neo4j-core/jars/#{jar}"
  end
  require "neo4j-core/node/embedded"
end

module Neo4j
end
