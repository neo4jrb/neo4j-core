module Neo4j::Embedded

  class Database
    extend Forwardable
    extend Neo4j::Core::TxMethods

    attr_reader :graph_db

    def_delegator :@graph_db, :schema
    def_delegator :@graph_db, :begin_tx
#    def_delegator :@graph_db, :create_node
    def_delegator :@graph_db, :getNodeById, :get_node_by_id
    def_delegator :@graph_db, :findNodesByLabelAndProperty, :find_nodes_by_label_and_property


    def initialize(path, config = {})
      start_embedded_db(path, config)
      @auto_commit = !!config[:auto_commit]
      Neo4j::Database.register_instance(self)
    end

    def start_embedded_db(path, config)
      factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
      if (config[:delete_existing_db])
        FileUtils.rm_rf path
      end

      @graph_db = factory.newEmbeddedDatabase(path)
    end

    def auto_commit?
      @auto_commit
    end

    def shutdown
      graph_db.shutdown
      Neo4j::Database.unregister_instance(self)
    end

    def create_node(properties = nil, labels=[])
      if labels.empty?
        _java_node = graph_db.create_node
      else
        labels = Neo4j::Embedded::Label.as_java(labels)
        _java_node = graph_db.create_node(labels)
      end

      properties.each_pair { |k, v| _java_node[k]=v } if properties
      _java_node
    end
    tx_methods :create_node

    def load_node(node_id)
      return nil unless node_id
      graph_db.get_node_by_id(node_id.to_i)
    rescue Java::OrgNeo4jGraphdb.NotFoundException
      nil
    end
    tx_methods :load_node

    # Checks if the given entity node or entity id (Neo4j::Node#neo_id) exists in the database.
    # @return [true, false] if exist
    def node_exist?(entity_or_entity_id)
      id = entity_or_entity_id.kind_of?(Fixnum) ? entity_or_entity_id : entity_or_entity_id.neo_id
      node = load_node(id)
      return false unless node
      node.has_property?('a')
      true
    rescue java.lang.IllegalStateException
      nil # the node has been deleted
    end
    tx_methods :node_exist?

    def create_label(name)
      Label.new(name)
    end
  end

end
