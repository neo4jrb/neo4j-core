require 'spec_helper'

describe Neo4j::Core::Index::IndexerRegistry do
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

      it "is not called if no property maches" do
        subject.indexers_for({'xtype' => 'foo', 'qame' => 'bar'}).to_a.size.should == 0
        subject.indexers_for({'ntype' => 'foo1', 'name' => 'qbar'}).to_a.size.should == 0
      end
    end

    describe "on_node_deleted" do
      it "calls Indexer#remove_index_on_fields once" do
        node = {}
        old_props = {'ntype' => 'foo'}
        deleted_relationship_set = {}
        deleted_node_identity_map = {}
        indexer.should_receive(:remove_index_on).with(node, old_props)
        subject.on_node_deleted(node, old_props, deleted_relationship_set, nil)
      end
    end

    describe "on_property_changed" do
      it "calls Indexer#update_index_on once" do
        node = {'ntype' => 'foo'}
        field = 'bar'
        old_val = "old"
        new_val = "new"

        indexer.should_receive(:update_index_on).with(node, field, old_val, new_val)
        subject.on_property_changed(node, field, old_val, new_val)
      end
    end


    describe "on_relationship_deleted" do
      it "calls Indexer#remove_index_on_fields once" do
        relationship = {}
        old_props = {'ntype' => 'foo'}
        deleted_relationship_set = {}
        deleted_node_identity_map = {}
        indexer.should_receive(:remove_index_on).with(relationship, old_props)
        subject.on_relationship_deleted(relationship, old_props, deleted_relationship_set, deleted_node_identity_map)
      end
    end

    describe "on_rel_property_changed" do
      it "calls Indexer#update_index_on once" do
        node = {'ntype' => 'foo'}
        field = 'bar'
        old_val = "old"
        new_val = "new"

        indexer.should_receive(:update_index_on).with(node, field, old_val, new_val)
        subject.on_rel_property_changed(node, field, old_val, new_val)
      end
    end


  end
end
