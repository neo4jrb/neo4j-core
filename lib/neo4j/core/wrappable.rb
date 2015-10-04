module Neo4j
  module Core
    module Wrappable
      def self.included(base)
        base.send :include, InstanceMethods
        base.extend ClassMethods
      end

      module InstanceMethods
        def wrap
          self.class.wrap(self)
        end
      end

      module ClassMethods
        def wrapper_callback(proc)
          fail 'Callback already specified!' if @wrapper_callback
          @wrapper_callback = proc
        end

        def clear_wrapper_callback
          @wrapper_callback = nil
        end

        def wrap(node)
          if @wrapper_callback
            @wrapper_callback.call(node)
          else
            node
          end
        end
      end
    end
  end
end
