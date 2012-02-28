module Neo4j
  module Core
    module Node
      module ClassMethods
        # Returns a new neo4j Node.
        # The return node is actually an Java object of type org.neo4j.graphdb.Node java object
        # which has been extended (see the included mixins for Neo4j::Node).
        #
        # The created node will have a unique id - Neo4j::Property#neo_id
        #
        # ==== Parameters
        # *args :: a hash of properties to initialize the node with or nil
        #
        # ==== Returns
        # org.neo4j.graphdb.Node java object
        #
        # ==== Examples
        #
        #  Neo4j::Transaction.run do
        #    Neo4j::Node.new
        #    Neo4j::Node.new :name => 'foo', :age => 100
        #  end
        #
        #
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
        rescue java.lang.IllegalStateException
          nil # the node has been deleted
        rescue Java::OrgNeo4jGraphdb.NotFoundException
          nil
        end

      end
    end
  end
end