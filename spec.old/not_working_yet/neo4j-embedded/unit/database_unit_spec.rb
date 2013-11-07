require 'spec_helper'

describe Neo4j::Node do

  let(:java_node) { mock("java_node", _set_db: nil) }

  let(:graph_db) { mock('graph db', create_node: java_node) }

  let(:db) do
    db = Neo4j::Embedded::Database.new('path')
    db.stub(:graph_db).and_return(graph_db)
    db
  end

  before do
    Neo4j::Embedded::Database.any_instance.stub(:start_embedded_db)
  end

  describe "node_exist?" do
    before { java_node.stub(:has_property?).and_return(true)}

    it "calls load_node" do
      db.should_receive(:load_node).with(42).and_return(java_node)
      db.node_exist?(42).should be_true
    end

    it "should allow argument responding to neo_id" do
      n = double("a node", neo_id: 123)
      db.should_receive(:load_node).with(123).and_return(java_node)
      db.node_exist?(n).should be_true
    end

    it "does not exist if it has been deleted (IllegalStateException)" do
      java_node.stub(:has_property?).and_raise(java.lang.IllegalStateException.new)
      db.should_receive(:load_node).with(42).and_return(java_node)
      db.node_exist?(42).should be_false
    end
  end


  describe "create_node" do

    it "can create properties" do
      java_node.should_receive(:[]=).with(:name, 'kalle')
      db.create_node(name: 'kalle').should == java_node
    end

    it "can be created without any properties and labels" do
      db.create_node.should == java_node
    end

    it "can create labels" do
      graph_db.should_receive(:create_node).with do |arg1, *args|
        arg1.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg1.name == "red"
      end.and_return(java_node)
      db.create_node({}, [:red]).should == java_node
    end

    it "can create many labels" do
      graph_db.should_receive(:create_node).with do |arg1, arg2, *args|
        arg1.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg1.name == "red" &&
            arg2.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg2.name == "green"
      end.and_return(java_node)

      db.create_node({}, [:red, :green]).should == java_node
    end

  end

  describe "load_node" do

    it "returns nil if node id is falsy" do
      db.load_node(false).should be_nil
    end

    it "returns the node if exists" do
      graph_db.should_receive(:get_node_by_id).with(42).and_return(java_node)
      db.load_node(42).should == java_node
    end

    it "convert string args to integer" do
      graph_db.should_receive(:get_node_by_id).with(42).and_return(java_node)
      db.load_node("42").should == java_node
    end

  end

  #describe "load" do
  #  let(:db) { mock('database', auto_commit?: false) }
  #  let(:wrapped_node) { mock('wrapped_node') }
  #
  #  before do
  #    Neo4j::Database.stub!(:instance).and_return db
  #  end
  #
  #  it "calls wrapper method" do
  #    clazz.should_receive(:_load).with(42, db).and_return(java_node)
  #    java_node.should_receive(:wrapper).and_return(wrapped_node)
  #    clazz.load(42).should == wrapped_node
  #  end
  #
  #  it "does not call wrapped method if node does not exist" do
  #    clazz.should_receive(:_load).with(42, db).and_return(nil)
  #    clazz.load(42).should be_nil
  #  end
  #end
end