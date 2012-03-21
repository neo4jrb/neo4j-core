module Neo4j
  module Core
    # Can be used to define your own wrapper class around nodes and relationships
    module Wrapper

      # @return [self, Object] return self or a wrapper Ruby object
      # @see  Neo4j::Node::ClassMethods#wrapper
      def wrapper
        self.class.wrapper(self)
      end
    end
  end
end
