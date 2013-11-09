# Plugin

Neo4j::Session.register_db(:embedded_db) do |*args|
  Neo4j::Embedded::EmbeddedSession.new(*args)
end

Neo4j::Session.register_db(:impermanent_db) do |*args|
  Neo4j::Embedded::EmbeddedImpermanentSession.new(*args)
end

module Neo4j::Embedded
  class EmbeddedSession < Neo4j::Session

    class Error < StandardError
    end

    attr_reader :graph_db, :db_location
    extend Forwardable
    extend Neo4j::Core::TxMethods
    def_delegator :@graph_db, :begin_tx


    def initialize(db_location, config={})
      @db_location = db_location
      @auto_commit = !!config[:auto_commit]
      Neo4j::Session.register(self)
    end

    def start
      raise Error.new("Embedded Neo4j db is already running") if running?
      puts "Start embedded Neo4j db at #{db_location}"
      factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
      @graph_db = factory.newEmbeddedDatabase(db_location)
    end

    def factory_class
      Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory
      Java::OrgNeo4jTest::ImpermanentGraphDatabase
    end

    def close
      super
      shutdown
    end

    def shutdown
      graph_db && graph_db.shutdown
      @graph_db = nil
    end

    def running?
      !!graph_db
    end

    def create_label(name)
      EmbeddedLabel.new(self, name)
    end

    def load_node(neo_id)
      _load_node(neo_id)
    end
    tx_methods :load_node

    # Same as load but does not return the node as a wrapped Ruby object.
    #
    def _load_node(neo_id)
      return nil if neo_id.nil?
      @graph_db.get_node_by_id(neo_id.to_i)
    rescue Java::OrgNeo4jGraphdb.NotFoundException
      nil
    end

    def load_relationship(neo_id)
      _load_relationship(neo_id)
    end
    tx_methods :load_relationship

    def _load_relationship(neo_id)
      return nil if neo_id.nil?
      @graph_db.get_relationship_by_id(neo_id.to_i)
    rescue Java::OrgNeo4jGraphdb.NotFoundException
      nil
    end

    def query(*params, &query_dsl)
      begin
        result = super
        raise CypherError.new(result.error_msg, result.error_code, result.error_status) if result.respond_to?(:error?) && result.error?
        # TODO ugly, the server database must convert the result
        result.respond_to?(:to_hash_enumeration) ? result.to_hash_enumeration : result.to_a
      rescue Exception => e
        raise CypherError.new(e,nil,nil)
      end
    end

    def find_all_nodes(label)
      EmbeddedLabel.new(self, label).find_nodes
    end

    def find_nodes(label, key, value)
      EmbeddedLabel.new(self, label).find_nodes(key,value)
    end

    # Performs a cypher query with given string.
    # Remember that you should close the resource iterator.
    # @param [String] q the cypher query as a String
    # @return (see #query)
    def _query(q, params={})
      engine = Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
      result = engine.execute(q, Neo4j::Core::HashWithIndifferentAccess.new(params))
      Neo4j::Cypher::ResultWrapper.new(result)
    end

    def query_default_return
      " RETURN n"
    end

    def _query_or_fail(q)
      engine = Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
      engine.execute(q)
    end

    def search_result_to_enumerable(result)
      result.map {|column| column['n']}
    end

    def create_node(properties = nil, labels=[])
      if labels.empty?
        _java_node = graph_db.create_node
      else
        labels = EmbeddedLabel.as_java(labels)
        _java_node = graph_db.create_node(labels)
      end
      properties.each_pair { |k, v| _java_node[k]=v } if properties
      _java_node
    end
    tx_methods :create_node

  end

  class EmbeddedImpermanentSession < EmbeddedSession
    def start
      raise Error.new("Embedded Neo4j db is already running") if running?
      #puts "Start test impermanent embedded Neo4j db at #{db_location}"
      @graph_db = Java::OrgNeo4jTest::TestGraphDatabaseFactory.new.newImpermanentDatabase()
    end
  end



end