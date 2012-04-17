module Neo4j
  module Core

    # A mixin which adds indexing behaviour to your own Ruby class
    # You are expected to implement the method `java_entity` returning the underlying Neo4j Node or Relationship.
    module Index

      # Adds an index on the given property
      # Notice that you normally don't have to do that since you simply can declare
      # that the property and index should be updated automatically by using the class method #index.
      #
      # The index operation will take place immediately unlike when using the Neo4j::Core::Index::ClassMethods#index
      # method which instead will guarantee that the neo4j database and the lucene database will be consistent.
      # It uses a two phase commit when the transaction is about to be committed.
      #
      # @see Neo4j::Core::Index::ClassMethods#add_index
      #
      def add_index(field, value=self[field])
        self.class.add_index(java_entity, field.to_s, value)
      end

      # Removes an index on the given property.
      # Just like #add_index this is normally not needed since you instead can declare it with the
      # #index class method instead.
      #
      # @see Neo4j::Core::Index::ClassMethods#rm_index
      #
      def rm_index(field, value=self[field])
        self.class.rm_index(java_entity, field.to_s, value)
      end

    end
  end

end