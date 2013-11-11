module Neo4j
  module Node
    class Rest
      attr_reader :session

      def initialize(attributes, labels, session)
        # Set the session
        @session = session
        # Create the node on the server
        @node = @session.neo.create_node(attributes)
        raise "Could not create the node on the server" if @node.nil?
        @session.neo.add_label(@node, labels)
      end

      def method_missing(get_or_set_property, *args)
        if match_data = /\A(\w+)\Z/.match(get_or_set_property)
          property = match_data[0]
          session.neo.get_node_properties(@node, [property])[property]
        elsif match_data = /\A(\w+=)\Z/.match(get_or_set_property)
          assert args.count == 1, "Syntax error"
          property = match_data[0]
          session.neo.set_node_properties(@node, property => args.first)
        else
          super
        end
      end
    end
  end
end