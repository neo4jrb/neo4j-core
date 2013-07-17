module Neo4j::Core
  module Initialize
    module ClassMethods
      extend Neo4j::Core::TxMethods

      # Returns a new neo4j Node.
      # The return node is actually an Java object of type Java::OrgNeo4jGraphdb::Node java object
      # which has been extended (see the included mixins for Neo4j::Node).
      #
      # The created node will have a unique id - Neo4j::Property#neo_id
      #
      # @example using default database
      #
      #   Neo4j::Node.new
      #   Neo4j::Node.new :name => 'foo', :age => 100
      #
      # @example using a different database
      #
      #   Neo4j::Node.new({:name => 'foo', :age => 100}, my_db)
      #
      # @param [Hash] properties an hash of properties or an array where the first item is the database
      #   to be used and the second item is the properties.
      # @param [Array<String,Neo4j::Database>] labels_or_db label names or the database to use which must be
      #   the last argument.
      # @return [Neo4j::Node] the java node which is actually a Java::OrgNeo4jGraphdb::Node java object
      def new(properties = nil, *labels_or_db)
        #db = labels_or_db.last.respond_to?(:create_node) ? labels_or_db.pop : Database.instance
        db = Neo4j::Core::ArgumentHelper.db(labels_or_db)
        labels = Neo4j::Label.as_java(labels_or_db)
        _java_node = labels ? db.create_node(labels) : db.create_node
        properties.each_pair {|k,v| _java_node[k]=v} if properties
        _java_node
      end
      tx_methods :new

      # Same as #load but does not return the node as a wrapped Ruby object.
      #
      # @return [Neo4j::Node]
      # @param [#to_i] node_id the id of the Neo4j node, see Neo4j::Node#neo_id
      # @param [Neo4j::Database] db the database, optionally
      def _load(node_id, db = Neo4j::Database.instance)
        return nil unless node_id
        db.get_node_by_id(node_id.to_i)
      rescue Java::OrgNeo4jGraphdb.NotFoundException
        nil
      end


      # Loads a node or wrapped node given a native java node or an id.
      # If there is a Ruby wrapper for the node then it will create and return a Ruby object that will
      # wrap the java node.
      #
      # @param [nil, #to_i] node_id the neo4j node id
      # @return [Object, Neo4j::Node, nil] If the node does not exist it will return nil otherwise the loaded node or wrapped node.
      def load(node_id, db = Neo4j::Database.instance)
        node = _load(node_id, db)
        node && node.wrapper
      end

    end
  end
end