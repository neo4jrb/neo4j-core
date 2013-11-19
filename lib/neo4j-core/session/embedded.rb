module Neo4j
  module Session
    class Embedded
      attr_accessor :auto_tx

      def initialize(path = "neo4j", auto_tx = true)
        raise "Cannot start a embedded session without JRuby" if RUBY_PLATFORM != 'java'
        @db_location = path
        @running = false
        @auto_tx = auto_tx
      end

      def running?
        @running
      end

      def database
        @db
      end

      def start
        return false if @started
        @started = true
        @db = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new.new_embedded_database(@db_location)
        @transaction = @db.begin_tx
        @running = true
      end

      def stop
        return false if @stopped
        @transaction.success
        @transaction.finish
        @db.shutdown
        @running = false
        @stopped = true
      end

      def run_transaction(&block)
        return unless block_given?
        transaction = @db.begin_tx
        result = yield
        transaction.success
        transaction.finish
        result
      end

      # Nodes
      # Create a new node. If auto_tx is true then we begin a new transaction and commit it after the creation
      def create_node(attributes, labels)
        if @auto_tx
          run_transaction { _create_node(attributes, labels) }
        else
          _create_node(attributes, labels)
        end
      end

      def load(id)
        @db.get_node_by_id(id)
      end

      def to_s
        @db_location
      end

      private
        def _create_node(attributes, labels)
          labels = labels.map { |label| Java::OrgNeo4jGraphdb::DynamicLabel.label(label) }
          node = @db.create_node(*labels)
          # Set properties
          attributes.each_pair do |key, value|
            node.set_property(key, value)
          end
          node
        end
    end
  end
end
