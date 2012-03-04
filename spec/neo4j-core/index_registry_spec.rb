require 'spec_helper'

describe Neo4j::Core::Index::Indexer do
  def node_index_config(&dsl)
    config = Neo4j::Core::Index::IndexConfig.new(:node)
    config.instance_eval(&dsl)
    config
  end
  let(:node_config) do
    node_index_config do
      index_names :exact => 'myindex_exact', :fulltext => 'myindex_fulltext'
      trigger_on :ntype => 'foo', :name => 'bar'
    end
  end

  context "create_for node_config" do
    let(:indexer) do
      Neo4j::Core::Index::Indexer.new(node_config)
    end

    subject do
      ir = Neo4j::Core::Index::IndexerRegistry.new
      ir.register(indexer)
      ir
    end

    describe "indexers_for" do
      it "is called once if one property matches" do
        subject.indexers_for({'ntype' => 'foo'}).to_a.size.should == 1
      end

      it "is still called once if two property maches" do
        subject.indexers_for({'ntype' => 'foo', 'name' => 'bar'}).to_a.size.should == 1
      end

    end

    describe "on_node_deleted" do
      it "is called once" do
        node = {}
        old_props = {'ntype' => 'foo'}
        deleted_relationship_set = {}

        indexer.should_receive(:remove_index_on_fields).with(node, old_props, deleted_relationship_set)
        subject.on_node_deleted(node, old_props, deleted_relationship_set, nil)
      end
    end
  end
end
