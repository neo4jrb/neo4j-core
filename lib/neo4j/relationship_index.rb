module Neo4j
  # You can use this if you don't want to create your own index class by extending the {Neo4j::Core::Index::ClassMethods} mixin.
  # Similar to {Neo4j::NodeIndex}
  #
  # @example
  #  Neo4j::RelationshipIndex.trigger_on(:typey => 123)
  #  Neo4j::RelationshipIndex.index(:name)
  #  a = Neo4j::Relationship.new(:friends, Neo4j::Node.new, Neo4j::Node.new, :typey => 123, :name => 'kalle')
  #  Neo4j::RelationshipIndex.find(:name => 'kalle').first.should be_nil
  #
  # @see Neo4j::NodeIndex
  class RelationshipIndex
    extend Neo4j::Core::Index::ClassMethods
    include Neo4j::Core::Index

    rel_indexer do
      index_names :exact => 'default_rel_index_exact', :fulltext => 'default_rel_index_fulltext'
    end

    # You must specify which nodes should be triggered.
    # The index can be triggered by one or more properties having one or more values.
    #
    # @example trigger on property :type being 'MyType1'
    #   Neo4j::RelationshipIndex.trigger_on(:type => 'MyType1')
    #
    def self.trigger_on(hash)
      _config.trigger_on(hash)
    end

  end

end