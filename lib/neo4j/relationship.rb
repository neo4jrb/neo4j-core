# external neo4j dependencies
require 'neo4j/property/property'
require 'neo4j/index/index'
require 'neo4j/equal'
require 'neo4j/load'
require 'neo4j/to_java'

module Neo4j


  # A relationship between two nodes in the graph. A relationship has a start node, an end node and a type.
  # You can attach properties to relationships with the API specified in Neo4j::JavaPropertyMixin.
  #
  # Relationship are created by invoking the << operator on the rels method on the node as follow:
  #  node.outgoing(:friends) << other_node << yet_another_node
  #
  # or using the Neo4j::Relationship#new method (which does the same thing):
  #  rel = Neo4j::Relationship.new(:friends, node, other_node)
  #
  # The fact that the relationship API gives meaning to start and end nodes implicitly means that all relationships have a direction.
  # In the example above, rel would be directed from node to otherNode.
  # A relationship's start node and end node and their relation to outgoing and incoming are defined so that the assertions in the following code are true:
  #
  #   a = Neo4j::Node.new
  #   b = Neo4j::Node.new
  #   rel = Neo4j::Relationship.new(:some_type, a, b)
  #   # Now we have: (a) --- REL_TYPE ---> (b)
  #
  #    rel.start_node # => a
  #    rel.end_node   # => b
  #
  # Furthermore, Neo4j guarantees that a relationship is never "hanging freely,"
  # i.e. start_node, end_node and other_node are guaranteed to always return valid, non-null nodes.
  #
  # === Wrapping
  #
  # Notice that the Neo4j::Relationship.new does not create a Ruby object. Instead, it returns a Java 
  # org.neo4j.graphdb.Relationship object which has been modified to feel more rubyish (like Neo4j::Node).
  #
  # === See also
  # * Neo4j::RelationshipMixin if you want to wrap a relationship with your own Ruby class.
  # * http://api.neo4j.org/1.4/org/neo4j/graphdb/Relationship.html
  #
  #
  class Relationship
    extend Neo4j::Core::Index::ClassMethods

    self.rel_indexer self

    class << self
      include Neo4j::Load
      include Neo4j::ToJava
      include Neo4j::Core::Relationship

      def extend_java_class(java_clazz)  #:nodoc:
        java_clazz.class_eval do
            include Neo4j::Property
            include Neo4j::Equal
            include Neo4j::Core::Relationship
          end

      end

      Neo4j::Relationship.extend_java_class(org.neo4j.kernel.impl.core.RelationshipProxy)

    end

  end

end


