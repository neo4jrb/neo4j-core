require 'neo4j/core/wrappable'
require 'active_support/core_ext/hash/keys'

module Neo4j
  module Core
    class Node
      attr_reader :id, :labels, :properties
      alias props properties

      include Wrappable

      # Perhaps we should deprecate this?
      alias neo_id id

      def initialize(id, labels, properties = {})
        @id = id
        @labels = labels.map(&:to_sym) unless labels.nil?
        @properties = properties.symbolize_keys
      end

      def ==(other)
        other.is_a?(Node) && neo_id == other.neo_id
      end

      class << self
        def from_url(url, properties = {})
          id = url.split('/')[-1].to_i
          labels = nil # unknown
          properties = properties

          new(id, labels, properties)
        end
      end
    end
  end
end
