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

      class << self
        def create_node(attributes, labels, session)
          node = session.neo.create_node(attributes)
          return nil if node.nil?
          session.neo.add_label(node, labels)
          Neo4j::Node::Rest.new(node, session)
        end

        def load(id, session)
          neo_node = session.neo.get_node(id)
          Neo4j::Node::Rest.new(neo_node, session)
        end
      end
    end
  end
end