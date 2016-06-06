require 'active_support/core_ext/hash/keys'

module Neo4j
  module Core
    class Relationship
      attr_reader :id, :type, :properties

      include Wrappable

      def initialize(id, type, properties, from_node_id = nil, to_node_id = nil)
        @id = id
        @type = type.to_sym unless type.nil?
        @properties = properties.symbolize_keys
        @from_node_id = from_node_id
        @to_node_id = to_node_id
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
