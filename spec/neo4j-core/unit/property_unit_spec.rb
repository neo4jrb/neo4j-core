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
  end
end