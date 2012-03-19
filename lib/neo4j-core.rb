require 'java'
include Java

module Neo4j
  # Enumerator has been moved to top level in Ruby 1.9.2, make it compatible with Ruby 1.8.7
  Enumerator = Enumerable::Enumerator unless defined? Enumerator
end

require 'neo4j/config'

require 'neo4j-community'

require 'neo4j/neo4j'

require 'neo4j-core/lazy_map'
require 'neo4j-core/relationship_set'
require 'neo4j-core/event_handler'
require 'neo4j-core/database'
require 'neo4j-core/to_java'

require 'neo4j-core/property/property'

require 'neo4j-core/rels/rels'
require 'neo4j-core/rels/traverser'

require 'neo4j-core/traversal/traversal'
require 'neo4j-core/traversal/traversal'
require 'neo4j-core/traversal/filter_predicate'
require 'neo4j-core/traversal/prune_evaluator'
require 'neo4j-core/traversal/rel_expander'
require 'neo4j-core/traversal/traverser'

require 'neo4j-core/index/index'
require 'neo4j-core/index/class_methods'
require 'neo4j-core/index/indexer_registry'
require 'neo4j-core/index/index_config'
require 'neo4j-core/index/indexer'
require 'neo4j-core/index/lucene_query'

require 'neo4j-core/equal/equal'

require 'neo4j-core/relationship/relationship'
require 'neo4j-core/relationship/class_methods'

require 'neo4j-core/node/node'
require 'neo4j-core/node/class_methods'

require 'neo4j/transaction'

require 'neo4j-core/type_converters/type_converters'

require 'neo4j-core/traversal/evaluator'
require 'neo4j-core/traversal/filter_predicate'
require 'neo4j-core/traversal/prune_evaluator'
require 'neo4j-core/traversal/rel_expander'
require 'neo4j-core/traversal/traversal'
require 'neo4j-core/traversal/traverser'

require 'neo4j-core/cypher/cypher'
require 'neo4j-core/cypher/result_wrapper'

require 'neo4j/cypher'
require 'neo4j/node'
require 'neo4j/relationship'