module Neo4j
  module Core
    # Can be used to define your own wrapper class around nodes and relationships
    module Wrapper

      # @return [self, Object] return self or a wrapper Ruby object
      # @see  Neo4j::Node::ClassMethods#wrapper
      def wrapper
        self.class.wrapper(self)
      end

      # This can be implemented by a wrapper to returned the underlying java node or relationship.
      # You can override this method in your own wrapper class.
      # @return self
      def _java_entity
        self
      end

      module ClassMethods

        # Tries to load a wrapper for this node if possible
        # @see #wrapper_proc=
        def wrapper(entity)
          @_wrapper_proc ? @_wrapper_proc.call(entity) : entity
        end

        # Sets the procs to be used to load wrappers
        # @see #wrapper
        def wrapper_proc=(proc)
          @_wrapper_proc = proc
        end

      end

    end
  end
end
