require 'spec_helper'

describe Neo4j::Core::Node, :type => :mock_db do

  let(:my_class) do
    klass = Class.new do
      extend Neo4j::Core::Node::ClassMethods
      include Neo4j::Core::Node
    end
  end

  let(:node) do
    MockNode.new
  end

  subject do
    Neo4j.started_db.graph.stub(:create_node) { node }
    my_class.new
  end

  describe "#del" do
    it "deletes then node" do
      node.should_receive(:get_relationships).with(Neo4j::Core::ToJava.dir_to_java(:both)).and_return(RelsIterator.new([]))
      node.should_receive(:delete)
      subject.del
    end


    it "deletes also deletes all relationships" do
      rel1 = MockRelationship.new
      rel2 = MockRelationship.new

      node.should_receive(:get_relationships).with(Neo4j::Core::ToJava.dir_to_java(:both)).and_return(RelsIterator.new([rel1, rel2]))
      rel1.should_receive(:delete)
      rel2.should_receive(:delete)
      node.should_receive(:delete)

      subject.del
    end
  end

  describe "#_java_node" do
    it "returns self" do
      subject._java_node.should == subject
    end
  end

  describe "#exist?" do
    it "returns self" do
      subject._java_node.should == subject
    end
  end

end
