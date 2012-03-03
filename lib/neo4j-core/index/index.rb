module Neo4j
  module Core

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
        converted_value = Neo4j::TypeConverters.convert(value, field, self.class)
        self.class.add_index(wrapper, field.to_s, converted_value)
      end

      # Removes an index on the given property.
      # Just like #add_index this is normally not needed since you instead can declare it with the
      # #index class method instead.
      #
      # @see Neo4j::Core::Index::ClassMethods#rm_index
      #
      def rm_index(field, value=self[field])
        self.class.rm_index(wrapper, field.to_s, value)
      end

    end
  end

end