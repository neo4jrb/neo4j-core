module Neo4j
  module Wrapper


    module Labels

      def self.included(klass)
        @_wrapped_classes ||= []
        @_wrapped_classes << klass
      end

      def self._wrapped_classes
        @_wrapped_classes
      end

      # @private
      def self._wrapped_classes=(wrapped_classes)
        @_wrapped_classes=wrapped_classes
      end

      # @private
      def self._wrapped_labels=(wl)
        @_wrapped_labels=(wl)
      end

      def self._wrapped_labels
        @_wrapped_labels ||=  @_wrapped_classes.inject({}) do |ack, clazz|
          ack.tap do |a|
            a[clazz.label] = clazz if clazz.respond_to?(:label)
          end
        end if @_wrapped_classes
      end

      module ClassMethods

        def label_names
          self.ancestors.find_all { |a| a.respond_to?(:label_name) }.map { |a| a.label_name }
        end

        def labels
          label_names.map{|label_name| Neo4j::Label.create(label_name)}
        end

        def label
          @_label ||= Neo4j::Label.create(label_name)
        end

        def label_name
          @_label_name || self.to_s
        end

        def set_label_name(name)
          @_label_name = name
        end
      end

    end

  end
end