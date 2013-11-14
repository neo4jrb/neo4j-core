require "neography"

module Neo4j
  module Session
    class Rest
      attr_reader :neo
      
      def initialize(url = "http://localhost:7474")
        @neo = Neography::Rest.new url
      end

      # These methods make no sense for a rest server so we just return true to make our specs happy
      def start
        true
      end

      alias :stop :start
      alias :running? :start

      def create_node(attributes, labels)
        node = @neo.create_node(attributes)
        return nil if node.nil?
        @neo.add_label(node, labels)
        Neo4j::Node::Rest.new(node, self)
      end

      def load(id)
        node = @neo.get_node(id)
        Neo4j::Node::Rest.new(node, self)
      end
    end
  end
end