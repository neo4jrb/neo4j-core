require 'spec_helper'

describe Neo4j::Node do

  let(:java_node) { mock("java_node") }

  describe "new" do
    it "can create properties" do
      java_node.should_receive(:[]=).with(:name, 'kalle')
      db = mock('database', create_node: java_node, auto_commit?: false)
      Neo4j::Database.stub!(:instance).and_return db
      Neo4j::Node.new(name: 'kalle').should == java_node
    end

    it "can be created without any properties and labels" do
      db = mock('database', create_node: java_node, auto_commit?: false)
      Neo4j::Database.stub!(:instance).and_return db
      Neo4j::Node.new.should == java_node
    end

    it "can create labels" do
      db = mock('database', auto_commit?: false)
      db.should_receive(:create_node).with do |arg1, *args|
        arg1.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg1.name == "red"
      end.and_return("newnode")

      Neo4j::Database.stub!(:instance).and_return db
      Neo4j::Node.new({}, :red).should == "newnode"
    end

    it "can create many labels" do
      db = mock('database', auto_commit?: false)
      db.should_receive(:create_node).with do |arg1, arg2, *args|
        arg1.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg1.name == "red" &&
            arg2.kind_of?(Java::OrgNeo4jGraphdb::DynamicLabel) && arg2.name == "green"
      end.and_return("newnode")

      Neo4j::Database.stub!(:instance).and_return db
      Neo4j::Node.new({}, :red, :green).should == "newnode"
    end

    it "can be created with a user defined database" do
      db = mock('database', create_node: java_node, auto_commit?: false)
      Neo4j::Node.new({},db).should == java_node
    end
  end

  describe "_load" do

  end
end