require 'spec_helper'

describe Neo4j::Core::Index::ClassMethods do

  let(:my_class) do
    klass = Class.new
    klass.extend Neo4j::Core::Index::ClassMethods
    klass
  end


  subject { my_class }
  describe "node_indexer" do
    it "configures an Indexer" do
      subject.node_indexer do
        index_names :exact => 'myindex_exact', :fulltext => 'myindex_fulltext'
        trigger_on :ntype => 'foo', :name => ['bar', 'bar2']
      end
      subject._indexer.config._index_names.should == {:exact => 'myindex_exact', :fulltext => 'myindex_fulltext'}
      subject._indexer.config._trigger_on['ntype'].to_a.should == ['foo']
      subject._indexer.config._trigger_on['name'].to_a.should == ['bar', 'bar2']
    end
  end

  [:index, :find, :index?, :has_index_type?, :rm_index_type, :rm_index_config, :add_index, :rm_index, :index_type].each do |meth|
    describe meth.to_s do
      it "forwards to the Neo4j::Core::Index::Indexer method #{meth}" do
        subject.should respond_to(meth)
        Neo4j::Core::Index::Indexer.instance_methods.should include(meth.to_s)
      end
    end
  end

end