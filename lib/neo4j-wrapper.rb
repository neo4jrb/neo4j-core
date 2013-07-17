require 'neo4j-core'

require 'neo4j-wrapper/labels'
require 'neo4j-wrapper/initialize'

#module Neo4j
#  module LabelMethod
#    def label
#      @_label || self
#    end
#
#    def label_with(name)
#      @_label = name
#    end
#  end
#
#  module LabelWrapper
#
#    module ClassMethods
#
#      def labels
#        self.ancestors.find_all{|a| a.respond_to?(:label)}.map{|a| a.label}
#      end
#
#      def included(klass)
#        klass.extend(ClassMethods)
#        klass.extend(Neo4j::LabelMethod)
#      end
#    end
#
#    def self.included(klass)
#      puts "HOJ #{klass}"
#      klass.extend(ClassMethods)
#      klass.extend(Neo4j::LabelMethod)
#    end
#
#  end
#
#  module NodeWrapper
#
#    def self.included(klass)
#      puts "NODE WRAPPER #{klass}"
#      klass.send(:include, Neo4j::LabelWrapper)
#      @_wrapped_classes ||= []
#      @_wrapped_classes << klass
#    end
#
#    def self._wrapped_classes
#      @_wrapped_classes
#    end
#
#    def self._wrapped_labels
#      @_wrapped_classes.map{|c| c.label}
#    end
#
#  end
#
#
#  module Foo
#    def self.label
#      "foo"
#    end
#  end
#
#  module Bar
#    def self.label
#      "bar"
#    end
#  end
#
#  class Base
#    def self.label
#      "base42"
#    end
#  end
#
#  class Thing < Base
#    include Foo
#    include Bar
#    include NodeWrapper
##    include LabelWrapper
#    label_with :thing
#  end
#
#  class Special < Thing
#    label_with :special
#  end
#
#  puts "THING #{Special.label} labels #{Special.labels.inspect}"
#
#end
