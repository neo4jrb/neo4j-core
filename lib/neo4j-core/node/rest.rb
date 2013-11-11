module Neo4j
  module Node
    class Rest
      attr_reader :session

      def initialize(attributes, labels, session)
        # Declare accessors
        attributes.each_pair do |key, value|
          self.class.send :attr_accessor, key.to_sym
          send (key.to_s+'=').to_sym, value
        end
        # Set the session
        @session = session
        # Create the node on the server
        @node = @session.neo.create_node(attributes)
        raise "Could not create the node on the server" if @node.nil?
        @session.neo.add_label(@node, labels)
      end
    end
  end
end