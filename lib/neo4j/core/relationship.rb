require 'neo4j/core/wrappable'

module Neo4j
  module Core
    class Relationship
      attr_reader :id, :type, :properties, :start_node_id, :end_node_id
      alias_method :props, :properties
      alias_method :neo_id, :id
      alias_method :rel_type, :type

      include Wrappable

      def initialize(id, type, properties, start_node_id, end_node_id)
        @id = id
        @type = type.to_sym unless type.nil?
        @properties = properties
        @start_node_id = start_node_id
        @end_node_id = end_node_id
      end

      class << self
        def from_url(url, properties = {})
          id = url.split('/')[-1].to_i
          type = nil # unknown
          properties = properties

          new(id, type, properties)
        end
      end
    end
  end
end
