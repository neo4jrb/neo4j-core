require 'spec_helper'

describe Neo4j::Core::Property do
  let(:node) do
    clazz = Class.new do
      include Neo4j::Core::Property
    end
    clazz.new
  end

  let(:mock_db) do
    double('mock db', auto_commit?: false)
  end

  before do
    Neo4j::Database.register_instance(mock_db)
  end

  after do
    Neo4j::Database.unregister_instance(mock_db)
  end

  describe '[]=' do
    it "sets the property if it is valid" do
      node.should_receive(:set_property).with('foo', 'bar')
      node['foo'] = 'bar'
    end

    it "raise Neo4j::InvalidPropertyException if value is not valid" do
      expect { node['foo'] = Object.new }.to raise_error(Neo4j::InvalidPropertyException)
    end

    it "will remove the property if value is nil" do
      node.should_receive(:remove_property).with('foo')
      node['foo'] = nil
    end
  end

  describe '[]' do
    it "returns nil if the property does not exist" do
      node.should_receive(:has_property?).and_return(false)
      node['bla'].should be_nil
    end

    it "returns the property if property exist" do
      node.should_receive(:has_property?).twice.and_return(true)
      node.should_receive(:get_property).twice.with("foo").and_return(42)
      node[:foo].should == 42
      node['foo'].should == 42
    end
  end

  describe 'props' do
    it "returns all properties" do
      node.should_receive(:property_keys).and_return(%w[a b c])
      node.stub(:get_property) { |x| "val:#{x}"}
      node.props.should == {'a' => 'val:a', 'b' => 'val:b', 'c' => 'val:c'}
    end
  end
end