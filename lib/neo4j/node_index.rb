module Neo4j
  # Provides some default values for a node index.
  # You can use this class as an example how to create your own index classes by extending the {Neo4j::Core::Index::ClassMethods} mixin.
  #
  # @example
  #   Neo4j::NodeIndex.trigger_on(:typex => 'MyTypeX')
  #   Neo4j::NodeIndex.index(:name)
  #   a = Neo4j::Node.new(:name => 'andreas', :typex => 'MyTypeX')
  #   finish_tx
  #   Neo4j::NodeIndex.find(:name => 'andreas').first.should == a
  #
  class NodeIndex
    extend Neo4j::Core::Index::ClassMethods
    include Neo4j::Core::Index

    node_indexer do
      index_names :exact => 'default_node_index_exact', :fulltext => 'default_node_index_fulltext'
    end

    # You must specify which nodes should be triggered.
    # The index can be triggered by one or more properties having one or more values.
    #
    # @example trigger on property :type being 'MyType1'
    #   Neo4j::NodeIndex.trigger_on(:type => 'MyType1')
    #
    def self.trigger_on(hash)
      _config.trigger_on(hash)
    end

  end

end