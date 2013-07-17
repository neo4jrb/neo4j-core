require 'spec_helper'

describe Neo4j::Core::Wrapper::ClassMethods, :type => :mock_db do

  let(:my_class) do
    klass = Class.new
    klass.extend Neo4j::Core::Wrapper::ClassMethods
    klass
  end

  describe "#wrapper" do
    it "returns the argument if no wrapper_proc" do
      my_class.wrapper("hoj").should == 'hoj'
    end

  end
  describe "#wrapper_proc=" do
    it "will be used in the wrapper method" do
      nodes = []
      my_class.wrapper_proc = Proc.new { |n| nodes << n; "mywrapper" }
      result = my_class.wrapper("Hello")
      nodes.should == ['Hello']
      result.should == "mywrapper"
    end
  end
end
