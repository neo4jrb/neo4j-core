require 'spec_helper'

describe Neo4j::Core::Property do

  let(:node_class) do
    Class.new do
      include Neo4j::Core::Property
      extend Neo4j::Core::Wrapper::ClassMethods

      attr_accessor :props

      def initialize(props={})
        @props = props.clone
      end

      def remove_property(key)
        @props.delete(key)
      end

      def set_property(key, value)
        @props[key] = value
      end

    end
  end

  describe "[]=" do
    subject { node_class.new }
    context 'when invalid value' do
      it 'should raise an exception' do
        Proc.new{subject[:foo] = Object.new}.should raise_error
      end

      it 'should not set the property' do
        Proc.new{subject[:foo] = Object.new}.should raise_error
        subject.props[:foo].should be_nil
      end
    end

    context 'when valid value' do
      it 'should set the property' do
        subject[:foo] = 'Kalle'
        subject.props['foo'].should == 'Kalle'
      end
    end
  end

  describe "update" do
    context "not strict" do
      let(:existing_props) do
        { 'a' => 1, 'b' => 2, '_thing' => 'Foo' }
      end

      let(:node) do
        node_class.new(existing_props)
      end

      it "does not delete old props" do
        node.update({})
        node.props.should == existing_props
      end

      it "should add props" do
        node.update({:new => 42})
        node.props.should == existing_props.merge("new" => 42)
      end

      it "should update existing props" do
        node.update({'b' => 42})
        node.props.should == {'a' => 1, 'b' => 42, '_thing' => 'Foo'}
      end

      it "should accept both strings and symbols as keys" do
        node.update({:b => 42})
        node.props.should == {'a' => 1, 'b' => 42, '_thing' => 'Foo'}
      end

      it "will never update a property starting with '_'" do
        node.update({'_thing' => 'newthing'})
        node.props.should == existing_props
      end
    end

    context ":strict => true" do
      let(:existing_props) do
        { 'a' => 1, 'b' => 2 }
      end

      let(:node) do
        node_class.new(existing_props)
      end

      it "does delete all old props" do
        node.update({}, :strict => true)
        node.props.should == {}
      end

      it "should add new props, but remove all old properties" do
        node.update({:new => 42}, :strict => true)
        node.props.should == {"new" => 42}
      end

      it "should update existing props but remove old props new being updated" do
        node.update({:b => 42}, :strict => true)
        node.props.should == {'b' => 42}
      end

      it "should keep protected properties _classname and _neo_id" do
        n = node_class.new('_classname' => 'Foo', '_neo_id' => 123, 'name' => 42, 'colour' => 'blue')
        n.update({'name' => "newname"}, :strict => true)
        n.props.should == {'_classname' => 'Foo', '_neo_id' => 123, 'name' => 'newname'}
      end
    end


    context ":protected_keys => ['a', 'b']" do
      let(:existing_props) do
        { 'a' => 1, 'b' => 2, 'c' => 3, '_classname' => 'Foo' }
      end

      let(:node) do
        node_class.new(existing_props)
      end

      it "can update existing properties if it's not a protected key'" do
        node.update({:c => 4}, :protected_keys => %w[a b])
        node.props['c'].should == 4
      end

      it "should add new props and remove all old properties except the protected keys" do
        node.update({:new => 42}, :protected_keys => %w[a b])
        node.props.should == {'a' => 1, 'b' => 2, "new" => 42}
      end

      it "can not update protected properties" do
        node.update({:b => 42}, :protected_keys => %w[a b])
        node.props.should == {'a' => 1, 'b' => 2}
      end

      it "should accept protected keys specified as symbols" do
        node.update({:b => 42}, :protected_keys => [:a, :b])
        node.props.should == {'a' => 1, 'b' => 2}
      end
    end

  end

end