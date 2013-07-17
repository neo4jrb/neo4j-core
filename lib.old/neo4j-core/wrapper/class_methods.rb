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

        def default_protected_keys
          %w(_neo_id _classname)
        end

        # @return [Array<String] which property keys are considered private, e.g. only used by a wrapper
        def protected_keys
          @_protected_keys || default_protected_keys
        end

        # let the wrapper tell which property keys should be considered private
        def protected_keys=(pk)
          @_protected_keys = pk
        end

      end
    end
  end
end
