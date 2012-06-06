module Neo4j


  # A relationship between two nodes in the graph. A relationship has a start node, an end node and a type.
  # You can attach properties to relationships like Neo4j::Node.
  #
  # The fact that the relationship API gives meaning to start and end nodes implicitly means that all relationships have a direction.
  # In the example above, rel would be directed from node to otherNode.
  # A relationship's start node and end node and their relation to outgoing and incoming are defined so that the assertions in the following code are true:
  #
  # Furthermore, Neo4j guarantees that a relationship is never "hanging freely,"
  # i.e. start_node, end_node and other_node are guaranteed to always return valid, non-nil nodes.
  #
  # === Wrapping
  #
  # Notice that the Neo4j::Relationship.new does not create a Ruby object. Instead, it returns a Java
  # Java::OrgNeo4jGraphdb::Relationship object which has been modified to feel more rubyish (like Neo4j::Node).
  #
  # @example
  #   a = Neo4j::Node.new
  #   b = Neo4j::Node.new
  #   rel = Neo4j::Relationship.new(:friends, a, b)
  #   # Now we have: (a) --- friends ---> (b)
  #
  #   rel.start_node # => a
  #   rel.end_node   # => b
  #
  # @example using the << operator on the Neo4j::Node relationship methods
  #
  #   node.outgoing(:friends) << other_node << yet_another_node
  #
  # @example lucene index
  #  Neo4j::Relationship.trigger_on(:typey => 123)
  #  Neo4j::Relationship.index(:name)
  #  a = Neo4j::Relationship.new(:friends, Neo4j::Node.new, Neo4j::Node.new, :typey => 123, :name => 'kalle')
  #  # Finish tx
  #  Neo4j::Relationship.find(:name => 'kalle').first.should be_nil
  #
  # @see http://api.neo4j.org/current/org/neo4j/graphdb/Relationship.html
  #
  class Relationship
    extend Neo4j::Core::Relationship::ClassMethods
    extend Neo4j::Core::Wrapper::ClassMethods
    extend Neo4j::Core::Index::ClassMethods

    include Neo4j::Core::Property
    include Neo4j::Core::Equal
    include Neo4j::Core::Relationship
    include Neo4j::Core::Wrapper
    include Neo4j::Core::Property::Java # for documentation purpose only
    include Neo4j::Core::Index


    # (see Neo4j::Core::Relationship::ClassMethods#new)
    def initialize(rel_type, start_node, end_node, props={})
    end


    rel_indexer do
      index_names :exact => 'default_rel_index_exact', :fulltext => 'default_rel_index_fulltext'
    end

    class << self
      def extend_java_class(java_clazz) #:nodoc:
        java_clazz.class_eval do
          include Neo4j::Core::Property
          include Neo4j::Core::Equal
          include Neo4j::Core::Relationship
          include Neo4j::Core::Wrapper
          include Neo4j::Core::Index
          alias_method :start_node, :start_node_wrapper
          alias_method :end_node, :end_node_wrapper
        end
      end

      Neo4j::Relationship.extend_java_class(Java::OrgNeo4jKernelImplCore::RelationshipProxy)
    end

  end

end


