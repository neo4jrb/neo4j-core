require 'ostruct'
require 'forwardable'
require 'fileutils'

require 'neo4j-core/version'
require 'neo4j/property_validator'
require 'neo4j/property_container'
require 'neo4j-core/active_entity'
require 'neo4j-core/helpers'
require 'neo4j-core/cypher_translator'
require 'neo4j-core/query_find_in_batches'
require 'neo4j-core/query'

require 'neo4j/entity_equality'
require 'neo4j/node'
require 'neo4j/label'
require 'neo4j/session'

require 'neo4j/relationship'
require 'neo4j/transaction'

require 'neo4j-server'

if RUBY_PLATFORM == 'java'
  require 'neo4j-embedded'
else
  # just for the tests
  module Neo4j
    module Embedded
    end
  end
end
