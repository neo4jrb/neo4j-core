module Neo4j
  module Core
    module Wrapper
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
