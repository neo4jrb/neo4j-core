require 'spec_helper'

describe "Neo4j::Wrapper::Labels and Neo4j::Wrapper::Initialize" do

  class MyThing
    include Neo4j::Wrapper::Initialize
    include Neo4j::Wrapper::Labels
    extend Neo4j::Wrapper::Initialize::ClassMethods
    extend Neo4j::Wrapper::Labels::ClassMethods
  end

  let(:java_node) { mock('java_node') }

  before do
    db = mock("db", create_node: java_node)
    Neo4j::Core::ArgumentHelper.stub!(:db).and_return(db)
    Neo4j::Label.stub!(:to_java).with(['MyThing']).and_return("thing_label")
  end

  describe "new" do
    it "can create a new node" do
      thing = MyThing.new
      thing._java_node.should == java_node
    end
  end

  describe ""
end

