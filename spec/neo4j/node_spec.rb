require 'spec_helper'

describe Neo4j::Node, :type => :mock_db do
  describe "#new" do
    it "created node should exist in db before transaction finish" do
      node = double("a node")
      Neo4j.db.graph.should_receive(:create_node).and_return(node)
      new_node = Neo4j::Node.new
      new_node.should == node
    end

    it "initialize it with the given hash of properties" do
      node = double("a node")
      Neo4j.db.graph.should_receive(:create_node).and_return(node)

      node.should_receive(:[]=).with(:name, 'my name')
      node.should_receive(:[]=).with(:age, 42)
      new_node = Neo4j::Node.new :name => 'my name', :age => 42
      new_node.should == node
    end

  end

  describe "#del" do
    it "should call the delete java method" do
      new_node = MockNode.new
      new_node.should_receive(:get_relationships).and_return([])
      new_node.should_receive(:delete)
      new_node.del.should be_nil
    end

    it "should delete all its relationships" do
      new_node = MockNode.new
      rel = double("Relationship")
      rel.should_receive(:del).once
      new_node.should_receive(:get_relationships).and_return([rel])
      new_node.should_receive(:delete)
      new_node.del.should be_nil
    end
  end

  describe "[]=" do
    it "should call the set_property java method" do
      new_node = MockNode.new
      new_node.should_receive(:set_property).with('foo', 42)
      new_node[:foo] = 42
    end

    it "should remove the property if set to nil" do
      new_node = MockNode.new
      new_node.should_receive(:remove_property).with('foo')
      new_node[:foo] = nil
    end

    {%w[abc def ghi] => :string, [42, 31] => :long, [3.14, 5.0] => :double, [true, false] => :boolean}.each_pair do |value, type|
      it "should allow arrays of #{value.inspect}" do
        new_node = MockNode.new
        value.should_receive(:to_java).with(type).and_return("something")
        new_node.should_receive(:set_property).with('foo', "something")
        new_node[:foo] = value
      end
    end

    it "should create a string array for empty arrays" do
      new_node = MockNode.new
      value = []
      java_class = [].to_java(:string).class
      new_node.should_receive(:set_property).with('foo', kind_of(java_class))
      new_node[:foo] = value
    end
  end

  describe "#update" do
    it "update properties" do
      new_node = MockNode.new
      new_node.should_receive(:set_property).with('kalle', 42)
      new_node.update(:kalle => 42)
    end

    it "update properties strict removed old properties" do
      new_node = MockNode.new
      new_node.stub(:props) { {"kalle" => 3, "hej" => "hoj"} }
      new_node.should_receive(:remove_property).with('hej')
      new_node.should_receive(:set_property).with('kalle', 42)
      new_node.update({:kalle => 42}, {:strict => true})
    end

  end

  describe "#load" do
    context "the node exists" do
      it "returns the node" do
        a_new_node = MockNode.new
        Neo4j.db.graph.should_receive(:get_node_by_id).and_return(a_new_node)
        Neo4j::Node.load(123).should == a_new_node
      end
    end

    context "the node does not exist" do
      it "returns nil" do
        Neo4j.db.graph.should_receive(:get_node_by_id).and_raise(Java::OrgNeo4jGraphdb::NotFoundException.new)
        Neo4j::Node.load(123).should be_nil
      end
    end

  end
end

