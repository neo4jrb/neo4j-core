module Neo4j
  module Core
    module Node
      module ClassMethods
        # Returns a new neo4j Node.
        # The return node is actually an Java object of type Java::OrgNeo4jGraphdb::Node java object
        # which has been extended (see the included mixins for Neo4j::Node).
        #
        #
        # The created node will have a unique id - Neo4j::Property#neo_id
        #
        # @param [Hash, Array] args either an hash of properties or an array where the first item is the database to be used and the second item is the properties
        # @return [Java::OrgNeo4jGraphdb::Node] the java node which implements the Neo4j::Node mixins
        #
        # @example using default database
        #
        #  Neo4j::Transaction.run do
        #    Neo4j::Node.new
        #    Neo4j::Node.new :name => 'foo', :age => 100
        #  end
        #
        # @example using a different database
        #
        #   Neo4j::Node.new({:name => 'foo', :age => 100}, my_db)
        def new(*args)
          # the first argument can be an hash of properties to set
          props = args[0].respond_to?(:each_pair) && args[0]

          # a db instance can be given, is the first argument if that was not a hash, or otherwise the second
          db = (!props && args[0]) || args[1] || Neo4j.started_db

          node = db.graph.create_node
          props.each_pair { |k, v| node[k]= v } if props
          node
        end

        # create is the same as new
        alias_method :create, :new


        # Same as load but does not return the node as a wrapped Ruby object.
        #
        def _load(node_id, db = Neo4j.started_db)
          return nil if node_id.nil?
          db.graph.get_node_by_id(node_id.to_i)
        rescue Java::OrgNeo4jGraphdb.NotFoundException
          nil
        end


        # Checks if the given entity node or entity id (Neo4j::Node#neo_id) exists in the database.
        # @return [true, false] if exist
        def exist?(entity_or_entity_id, db = Neo4j.started_db)
          id = entity_or_entity_id.kind_of?(Fixnum) ? entity_or_entity_id : entity_or_entity_id.id
          node = _load(id, db)
          return false unless node
          node.has_property?('a')
          true
        rescue java.lang.IllegalStateException
          nil # the node has been deleted
        end

        # Loads a node or wrapped node given a native java node or an id.
        # If there is a Ruby wrapper for the node then it will create and return a Ruby object that will
        # wrap the java node.
        #
        # @param [nil, #to_i] node_id the neo4j node id
        # @return [Object, Neo4j::Node, nil] If the node does not exist it will return nil otherwise the loaded node or wrapped node.
        def load(node_id, db = Neo4j.started_db)
          node = _load(node_id, db)
          node && node.wrapper
        end

      end
    end
  end
end