module Neo4j
  autoload :Session, "neo4j-core/session"
  autoload :Node, "neo4j-core/node"
  autoload :Label, "neo4j-core/label"
end

# If the platform is Java then load all java related files
if RUBY_PLATFORM == 'java'
  require "java"
  Dir["#{Dir.pwd}/lib/neo4j-core/jars/*.jar"].each do |jar|
    jar = File.basename(jar)
    require "neo4j-core/jars/#{jar}"
  end
  require "neo4j-core/node/embedded"
end
