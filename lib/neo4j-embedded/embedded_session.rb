module Neo4j::Embedded
  class EmbeddedSession < Neo4j::Session
    attr_reader :graph_db, :db_location
    extend Forwardable
    def_delegator :@graph_db, :begin_tx


    def initialize(db_location, config={})
      @db_location = db_location
      @auto_commit = !!config[:auto_commit]
      Neo4j::Session.register(self)
    end

    def start
      @graph_db = EmbeddedDatabase.create_db(db_location)
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

    def create_node(properties = nil, labels=[])
      if labels.empty?
        _java_node = graph_db.create_node
      else
        labels = EmbeddedLabel.as_java(labels)
        _java_node = graph_db.create_node(labels)
      end
# TODO
#      properties.each_pair { |k, v| _java_node[k]=v } if properties
      _java_node
    end
#    tx_methods :create_node

  end
end