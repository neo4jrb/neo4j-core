require 'forwardable'
require 'fileutils'

require 'neo4j-cypher'

require 'neo4j-core/helpers'
require 'neo4j-core/property'
require 'neo4j/exceptions'
require 'neo4j/database'

require 'neo4j/node'
require 'neo4j/relationship'
require 'neo4j/transaction'

require 'neo4j-server'
require 'neo4j-embedded' if RUBY_PLATFORM == 'java'

#require 'neo4j-wrapper' # TODO should be move to a separate gem
