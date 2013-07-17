require 'spec_helper'

describe Neo4j::Wrapper::Initialize do

  thingClass = Class.new do
    include Neo4j::Wrapper::Initialize
    extend Neo4j::Wrapper::Initialize::ClassMethods

    def self.labels
      ['Thing']
    end
  end

  let(:java_node) { mock('java_node') }


  describe "load_entity" do
    it "foo" do
      pending
      db = mock("db", get_node_by_id: java_node)
      thingClass.load_entity
    end
  end

  describe "new" do
    before do
      db = mock("db", create_node: java_node)
      Neo4j::Core::ArgumentHelper.stub!(:db).and_return(db)
      Neo4j::Label.stub!(:to_java).with(['Thing']).and_return("thing_label")
    end

    it "sets the _java_node/_java_entity" do
      thing = thingClass.new
      thing._java_entity.should == java_node
      thing._java_node.should == java_node
    end

    it "sets properties on the node" do
      # then
      java_node.should_receive(:[]=).with(:a, 1)
      db = mock("db", create_node: java_node)

      # when
      thingClass.new(:a => 1)
    end

    it "calls the init_on_load method" do
      clazz = Class.new(thingClass) do
        attr_reader :foo
        def init_on_load(node)
          @foo = 1
          super
        end
      end
      thing = clazz.new
      thing._java_entity.should == java_node
      thing.foo.should == 1
    end


    it "calls the init_on_create method" do
      clazz = Class.new(thingClass) do
        attr_reader :arg1, :arg2
        def init_on_create(arg1,arg2)
          @arg1 = arg1
          @arg2 = arg2
          super
        end
      end
      thing = clazz.new(10,20)
      thing._java_entity.should == java_node
      thing.arg1.should == 10
      thing.arg2.should == 20
    end
  end

end

