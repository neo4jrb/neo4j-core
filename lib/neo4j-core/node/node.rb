module Neo4j

  module Core
    module Node
      def del #:nodoc:
        _rels.each { |r| r.del }
        delete
        nil
      end

      def exist?
        Neo4j::Node.exist?(self)
      end

      def wrapped_entity
        self
      end

      def wrapper
        self.class.wrapper(self)
      end

      def _java_node
        self
      end

      def class
        Neo4j::Node
      end
    end
  end
end