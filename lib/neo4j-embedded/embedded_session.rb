# Plugin

Neo4j::Session.register_db(:embedded_db) do |*args|
  Neo4j::Embedded::EmbeddedSession.new(*args)
end

module Neo4j
  module Embedded
    class EmbeddedSession < Neo4j::Session
      class Error < StandardError
      end

      attr_reader :graph_db, :db_location, :properties_file, :properties_map
      extend Forwardable
      extend Neo4j::Core::TxMethods
      def_delegator :@graph_db, :begin_tx

      def initialize(db_location, config = {})
        @config          = config
        @db_location     = db_location
        @auto_commit     = !!@config[:auto_commit]
        @properties_file = @config[:properties_file]
        Neo4j::Session.register(self)
      end

      def properties_map
        return @properties_map if @properties_map

        props = if @config[:properties_map].is_a?(Hash)
                  @config[:properties_map].each_with_object({}) do |(k, v), m|
                    m[k.to_s.to_java] = v.to_s.to_java
                  end
                else
                  {}
                end
        @properties_map = java.util.HashMap.new(props)
      end

      def db_type
        :embedded_db
      end

      def inspect
        "#{self.class} db_location: '#{@db_location}', running: #{running?}"
      end

      def version
        # Wow
        # Yeah, agreed...
        version_string = @graph_db.to_java(Java::OrgNeo4jKernel::GraphDatabaseAPI).getDependencyResolver.resolveDependency(Java::OrgNeo4jKernel::KernelData.java_class).version.to_s
        version_string.split(' ')[-1]
      end

      def start
        fail Error, 'Embedded Neo4j db is already running' if running?
        puts "Start embedded Neo4j db at #{db_location}"
        factory    = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
        db_service = factory.newEmbeddedDatabaseBuilder(db_location)
        db_service.loadPropertiesFromFile(properties_file) if properties_file
        db_service.setConfig(properties_map)               if properties_map

        @graph_db = db_service.newGraphDatabase
        Neo4j::Session._notify_listeners(:session_available, self)
        @engine = Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
      end

      def factory_class
        Java::OrgNeo4jTest::ImpermanentGraphDatabase
      end

      def close
        super
        shutdown
      end

      def self.transaction_class
        Neo4j::Embedded::EmbeddedTransaction
      end

      # Duplicate of CypherSession::Adaptor::Base#transaction
      def transaction
        return self.class.transaction_class.new(self) if !block_given?

        begin
          tx = transaction

          yield tx
        rescue Exception => e # rubocop:disable Lint/RescueException
          tx.mark_failed

          raise e
        ensure
          tx.close
        end
      end

      def shutdown
        @graph_db && @graph_db.shutdown

        Neo4j::Session.clear_listeners
        @graph_db = nil
      end

      def running?
        !!@graph_db
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

      def query(*args)
        if [[String], [String, Hash]].include?(args.map(&:class))
          query, params = args[0, 2]
          Neo4j::Embedded::ResultWrapper.new(_query(query, params), query)
        else
          options = args[0] || {}
          Neo4j::Core::Query.new(options.merge(session: self))
        end
      end


      def find_all_nodes(label)
        EmbeddedLabel.new(self, label).find_nodes
      end

      def find_nodes(label, key, value)
        EmbeddedLabel.new(self, label).find_nodes(key, value)
      end

      # Performs a cypher query with given string.
      # Remember that you should close the resource iterator.
      # @param [String] q the cypher query as a String
      # @return (see #query)
      def _query(query, params = {}, options = {})
        ActiveSupport::Notifications.instrument('neo4j.cypher_query', params: params, context: options[:context],
                                                                      cypher: query, pretty_cypher: options[:pretty_cypher], params: params) do
          @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
          @engine.execute(query, indifferent_params(params))
        end
      rescue StandardError => e
        raise Neo4j::Session::CypherError.new(e.message, e.class, 'cypher error')
      end

      def indifferent_params(params)
        return {} unless params
        params.each { |k, v| params[k] = HashWithIndifferentAccess.new(params[k]) if v.is_a?(Hash) && !v.respond_to?(:nested_under_indifferent_access) }
        HashWithIndifferentAccess.new(params)
      end

      def query_default_return(as)
        " RETURN #{as}"
      end

      def _query_or_fail(q)
        @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
        @engine.execute(q)
      end

      def search_result_to_enumerable(result)
        result.map { |column| column['n'].wrapper }
      end

      def create_node(properties = nil, labels = [])
        if labels.empty?
          @graph_db.create_node
        else
          labels = EmbeddedLabel.as_java(labels)
          @graph_db.create_node(labels)
        end.tap do |java_node|
          properties.each_pair { |k, v| java_node[k] = v } if properties
        end
      end
      tx_methods :create_node
    end
  end
end
