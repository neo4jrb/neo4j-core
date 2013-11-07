require 'java'

# TODO: release neo4j-community jar 2.0
# Load Neo4j Jars for the jars folder
jar_folder = File.expand_path('../neo4j/jars', __FILE__)
jars = Dir.new(jar_folder).entries.find_all { |x| x =~ /\.jar$/ }
jars.each { |jar| require File.expand_path(jar, jar_folder) }

require 'neo4j-embedded/to_java'
require 'neo4j-embedded/embedded_session'
require 'neo4j-embedded/embedded_label'
require 'neo4j-embedded/embedded_node'
require 'neo4j-embedded/embedded_relationship'
require 'neo4j-embedded/embedded_label'

# TODO replace this with https://github.com/intridea/hashie gem
require 'neo4j-core/hash_with_indifferent_access'