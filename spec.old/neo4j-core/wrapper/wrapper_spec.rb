require 'spec_helper'

describe Neo4j::Core::Wrapper, :type => :mock_db do

  let(:my_class) do
    klass = Class.new do
      extend Neo4j::Core::Wrapper::ClassMethods
      include Neo4j::Core::Wrapper
    end
  end

  let(:node) do
    MockNode.new
  end


  describe "#wrapper" do
    context "when no defined wrapper" do
      it "does return the node" do
        n = my_class.new
        n.wrapper.should == n
      end
    end

    context "when there is a defined wrapper proc" do


      it "does return the node" do
        nodes = []
        my_class.wrapper_proc = Proc.new{|n| nodes << n; "hej"}
        n = my_class.new
        n.wrapper.should == "hej"
        nodes.should == [n]
      end
    end

  end
end

