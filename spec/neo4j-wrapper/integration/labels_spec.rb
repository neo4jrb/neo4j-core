require 'spec_helper'

describe "Neo4j::Wrapper::Labels and Neo4j::Wrapper::Initialize" do

  class MyThing
    include Neo4j::Wrapper::Initialize
    include Neo4j::Wrapper::Labels
    extend Neo4j::Wrapper::Initialize::ClassMethods
    extend Neo4j::Wrapper::Labels::ClassMethods
  end

  let(:java_node) { double('java_node') }

  let(:db) { double("db", create_node: java_node) }

  before do
    Neo4j::Database.register_instance(db)
    Neo4j::Label.stub(:to_java).with(['MyThing']).and_return("thing_label")
  end

  after do
    Neo4j::Database.unregister_instance(db)
  end

  describe "new" do
    it "can create a new node" do
      db.should_receive(:create_label).with("MyThing")
      thing = MyThing.create
      thing._java_node.should == java_node
    end
  end
end

