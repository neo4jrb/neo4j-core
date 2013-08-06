require 'java'

# TODO: release neo4j-community jar 2.0
# Load Neo4j Jars for the jars folder
jar_folder = File.expand_path('../neo4j/jars', __FILE__)
jars = Dir.new(jar_folder).entries.find_all { |x| x =~ /\.jar$/ }
jars.each { |jar| require File.expand_path(jar, jar_folder) }

require 'neo4j-embedded/label'
require 'neo4j-embedded/database'
require 'neo4j-embedded/node'

