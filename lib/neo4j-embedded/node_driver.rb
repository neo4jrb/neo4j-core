module Neo4j
  module Embedded
    module NodeDriver
      extend Neo4j::Core::TxMethods

      def create_node(properties = nil, *labels_or_db)
        #db = labels_or_db.last.respond_to?(:create_node) ? labels_or_db.pop : Database.instance
        db = Neo4j::Core::ArgumentHelper.db(labels_or_db)
        labels = Neo4j::Embedded::Label.as_java(labels_or_db)
        _java_node = labels ? db.create_node(labels) : db.create_node
        properties.each_pair { |k, v| _java_node[k]=v } if properties
        _java_node
      end
      tx_methods :create_node

      def _load(node_id, db = Neo4j::Database.instance)
        return nil unless node_id
        db.get_node_by_id(node_id.to_i)
      rescue Java::OrgNeo4jGraphdb.NotFoundException
        nil
      end

      extend self
    end
  end
end