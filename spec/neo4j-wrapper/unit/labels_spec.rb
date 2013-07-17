require 'spec_helper'

describe Neo4j::Wrapper::Labels::ClassMethods do
  describe 'labels' do
    it 'returns the label of a class' do
      clazz = Class.new do
        extend Neo4j::Wrapper::Labels::ClassMethods
        def self.label
          "mylabel"
        end
      end
      clazz.labels.should == ['mylabel']
    end

    it "returns all labels for inherited ancestors which have a label method" do
      baseClass = Class.new do
        def self.label
          "base"
        end
      end

      clazz = Class.new(baseClass) do
        extend Neo4j::Wrapper::Labels::ClassMethods
        def self.label
          "mylabel"
        end
      end

      clazz.labels.should =~ ['base', 'mylabel']
    end

    it "returns all labels for included modules which have a label class method" do
      module1 = Module.new do
        def self.label
          "module1"
        end
      end

      module2 = Module.new do
        def self.label
          "module2"
        end
      end

      clazz = Class.new do
        extend Neo4j::Wrapper::Labels::ClassMethods
        include module1
        include module2
      end

      clazz.labels.should =~ ['module1', 'module2']
    end

  end
end