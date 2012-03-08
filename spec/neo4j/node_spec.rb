require 'spec_helper'

describe Neo4j::Node, :type => :mock_db do
  before do
    Neo4j::Core::ToJava.stub(:type_to_java) { |x| x }
    Neo4j::Core::ToJava.stub(:dir_to_java) { |x| x }
  end

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

    it "does not update properties starting with character '_'" do
      new_node = MockNode.new
      new_node.update({:_kalle => 42})
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

  describe "node and _node" do
    let(:other_node) { MockNode.new }
    subject { MockNode.new }

    it "returns a single (wrapped) node" do
      other_node.should_receive(:wrapper).and_return("the wrapper")
      rel = MockRelationship.new(:foo, subject, other_node)
      subject.should_receive(:get_single_relationship).with(:foo, :outgoing).and_return(rel)
      subject.node(:outgoing, :foo).should == "the wrapper"
    end

    it "returns a single node" do
      other_node.should_not_receive(:wrapper)
      rel = MockRelationship.new(:foo, subject, other_node)
      subject.should_receive(:get_single_relationship).with(:foo, :outgoing).and_return(rel)
      subject._node(:outgoing, :foo).should == other_node
    end
  end


  describe "rel and _rel" do
    subject { MockNode.new }

    let(:other_node) { MockNode.new }

    it "returns a single (wrapped) relationship" do
      rel = MockRelationship.new(:foo, subject, other_node)
      rel.should_receive(:wrapper).and_return("the wrapper")
      subject.should_receive(:get_single_relationship).with(:foo, :outgoing).and_return(rel)
      subject.rel(:outgoing, :foo).should == "the wrapper"
    end

    it "returns a single relationship" do
      rel = MockRelationship.new(:foo, subject, other_node)
      rel.should_not_receive(:wrapper)
      subject.should_receive(:get_single_relationship).with(:foo, :outgoing).and_return(rel)
      subject._rel(:outgoing, :foo).should == rel
    end
  end

  describe "rel?" do
    subject { MockNode.new }

    let(:other_node) { MockNode.new }

    it "accept two arguments" do
      subject.should_receive(:has_relationship).with(:outgoing, :foo).and_return(true)
      subject.rel?(:outgoing, :foo).should be_true
    end

    it "accept no arguments" do
      subject.should_receive(:has_relationship).with().and_return(true)
      subject.rel?.should be_true
    end
  end

  describe "_rels" do
    subject { MockNode.new }

    #it "returns a Neo4j::Core::Rels::Traverser object" do
    #  subject.rels
    #end

    it "accept no arguments which return both direction all types" do
      subject.should_receive(:get_relationships).with(:both).and_return("stuff")
      subject._rels.should == "stuff"
    end

    it "accept one direction argument which return only relationship of that direction but of any type" do
      subject.should_receive(:get_relationships).with(:incoming).and_return("stuff")
      subject._rels(:incoming).should == "stuff"
    end

  end
end

