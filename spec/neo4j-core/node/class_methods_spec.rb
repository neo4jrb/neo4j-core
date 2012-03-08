require 'spec_helper'

describe Neo4j::Core::Node::ClassMethods, :type => :mock_db do

  let(:my_class) do
    klass = Class.new
    klass.extend Neo4j::Core::Node::ClassMethods
    klass
  end

  describe "new" do
    it "returns a new node" do
      new_node = mock("new node")
      Neo4j.db.graph.should_receive(:create_node).and_return(new_node)
      my_class.new.should == new_node
    end

    it "can initialize the properties" do
      new_node = mock("new node")
      new_node.should_receive(:[]=).with(:foo, 42)
      Neo4j.db.graph.should_receive(:create_node).and_return(new_node)
      my_class.new(:foo => 42).should == new_node
    end

    it "can use a different database" do
      new_node = mock("new node")
      other_db = mock("other db")
      graph_db = mock("graph db")
      other_db.should_receive(:graph).and_return(graph_db)
      graph_db.should_receive(:create_node).and_return(new_node)
      my_class.new(other_db).should == new_node
    end

    it "can use a different database and initialize its properties" do
      new_node = mock("new node")
      other_db = mock("other db")
      graph_db = mock("graph db")
      new_node.should_receive(:[]=).with(:foo, 42)
      other_db.should_receive(:graph).and_return(graph_db)
      graph_db.should_receive(:create_node).and_return(new_node)
      my_class.new({:foo => 42}, other_db).should == new_node
    end

  end
end
