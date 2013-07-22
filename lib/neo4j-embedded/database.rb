module Neo4j::Embedded

  class Database
    extend Forwardable

    def_delegator :@graph_db, :schema
    def_delegator :@graph_db, :begin_tx
    def_delegator :@graph_db, :create_node
    def_delegator :@graph_db, :getNodeById, :get_node_by_id
    def_delegator :@graph_db, :findNodesByLabelAndProperty, :find_nodes_by_label_and_property


    def initialize(path, config = {})
      factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
      if (config[:delete_existing_db])
        FileUtils.rm_rf path
      end

      @graph_db = factory.newEmbeddedDatabase(path)
      @auto_commit = !!config[:auto_commit]
      Neo4j::Database.set_instance(self)
    end

    def driver_for(clazz)
      return RestNode
    end

    def auto_commit?
      @auto_commit
    end

    def shutdown
      @graph_db.shutdown
      Neo4j::Database.set_instance(nil)
    end
  end

end
