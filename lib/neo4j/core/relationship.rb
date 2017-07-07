require 'neo4j/core/wrappable'
require 'active_support/core_ext/hash/keys'

module Neo4j
  module Core
    class Relationship
      attr_reader :id, :type, :properties, :start_node_id, :end_node_id
      alias props properties
      alias neo_id id
      alias start_node_neo_id start_node_id
      alias end_node_neo_id end_node_id
      alias rel_type type

      include Wrappable

      def initialize(id, type, properties, start_node_id = nil, end_node_id = nil)
        @id = id
        @type = type.to_sym unless type.nil?
        @properties = properties.symbolize_keys
        @start_node_id = start_node_id
        @end_node_id = end_node_id
      end

      class << self
        def from_url(url, properties = {})
          id = url.split('/')[-1].to_i
          type = nil # unknown
          properties = properties

          new(id, type, properties, nil, nil)
        end
      end
    end
  end
end
