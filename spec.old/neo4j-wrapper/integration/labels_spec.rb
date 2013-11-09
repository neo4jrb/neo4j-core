require 'spec_helper'

describe "Neo4j::Wrapper::Labels and Neo4j::Wrapper::Initialize" do

  class MyThing
    include Neo4j::Wrapper::Initialize
    include Neo4j::Wrapper::Labels
    extend Neo4j::Wrapper::Initialize::ClassMethods
    extend Neo4j::Wrapper::Labels::ClassMethods
  end

  let(:unwrapped_node) { double('unwrapped_node') }

  before do
    @session = double("Mock Session")
    Neo4j::Session.stub(:current).and_return(@session)
  end

  describe "new" do
    it "can create a new wrapped node" do
      @session.should_receive(:create_node).with(nil, [:MyThing]).and_return(unwrapped_node)
      thing = MyThing.create
      thing._unwrapped_node.should == unwrapped_node
      thing.class.should == MyThing
    end
  end
end

