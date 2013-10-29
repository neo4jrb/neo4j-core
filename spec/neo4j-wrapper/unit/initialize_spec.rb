require 'spec_helper'

describe Neo4j::Wrapper::Initialize do

  thingClass = Class.new do
    include Neo4j::Wrapper::Initialize
    extend Neo4j::Wrapper::Initialize::ClassMethods

    def self.labels
      ['Thing']
    end
  end

  let(:java_node) { double('java_node') }


  describe "create" do
    before do
      @session = double("Session")
      Neo4j::Session.stub(:current).and_return(@session)
    end

    it "sets the _java_node/_unwrapped_node" do
      @session.should_receive(:create_node).with(nil, []).and_return(java_node)
      thing = thingClass.create
      thing._unwrapped_node.should == java_node
    end

    it "sets properties on the node" do
      # then
      @session.should_receive(:create_node).with({a: 1}, []).and_return(java_node)

      # when
      thingClass.create(:a => 1)
    end

    it "calls the init_on_load method" do
      clazz = Class.new(thingClass) do
        attr_reader :foo
        def init_on_load(node)
          @foo = 1
          super
        end
      end
      @session.should_receive(:create_node).with(nil, []).and_return(java_node)
      thing = clazz.create
      thing._unwrapped_node.should == java_node
      thing.foo.should == 1
    end

  end

end

