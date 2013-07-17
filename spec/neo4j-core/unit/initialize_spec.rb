require 'spec_helper'

describe Neo4j::Node do

  let(:java_node) { mock("java_node") }

  clazz = Class.new do
    extend Neo4j::Core::Initialize::ClassMethods
  end


  describe "new" do
    let(:db) { mock('database', create_node: java_node, auto_commit?: false) }

    before do
      Neo4j::Database.stub!(:instance).and_return db
    end

    it "can create properties" do
      java_node.should_receive(:[]=).with(:name, 'kalle')
      clazz.new(name: 'kalle').should == java_node
    end

    it "can be created without any properties and labels" do
      clazz.new.should == java_node
    end

    it "can create labels" do
      db.should_receive(:create_node).with do |arg1, *args|
        arg1.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg1.name == "red"
      end.and_return("newnode")
      clazz.new({}, :red).should == "newnode"
    end

    it "can create many labels" do
      db.should_receive(:create_node).with do |arg1, arg2, *args|
        arg1.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg1.name == "red" &&
            arg2.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg2.name == "green"
      end.and_return("newnode")

      clazz.new({}, :red, :green).should == "newnode"
    end

    it "can be created with a user defined database" do
      clazz.new({},db).should == java_node
    end
  end

  describe "_load" do
    let(:db) { mock('database', auto_commit?: false) }

    before do
      Neo4j::Database.stub!(:instance).and_return db
    end

    it "returns nil if node id is falsy" do
      clazz._load(false).should be_nil
    end

    it "returns the node if exists" do
      db.should_receive(:get_node_by_id).with(42).and_return(java_node)
      clazz._load(42).should == java_node
    end

    it "convert string args to integer" do
      db.should_receive(:get_node_by_id).with(42).and_return(java_node)
      clazz._load("42").should == java_node
    end

    it "let you use your own database" do
      db.should_receive(:get_node_by_id).with(42).and_return(java_node)
      clazz._load(42, db).should == java_node
    end
  end

  describe "load" do
    let(:db) { mock('database', auto_commit?: false) }
    let(:wrapped_node) { mock('wrapped_node') }

    before do
      Neo4j::Database.stub!(:instance).and_return db
    end

    it "calls wrapper method" do
      clazz.should_receive(:_load).with(42, db).and_return(java_node)
      java_node.should_receive(:wrapper).and_return(wrapped_node)
      clazz.load(42).should == wrapped_node
    end

    it "does not call wrapped method if node does not exist" do
      clazz.should_receive(:_load).with(42, db).and_return(nil)
      clazz.load(42).should be_nil
    end
  end
end