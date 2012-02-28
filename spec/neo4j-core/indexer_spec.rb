require 'spec_helper'

describe Neo4j::Core::Index::Indexer do


  describe "node index" do
    let(:node_index) do
      clazz = double("Class")
      Neo4j::Core::Index::Indexer.new(clazz, :node)
    end

    subject { node_index }
    its(:to_s) { should be_a(String) }

    context "when indexed :foo" do
      before do
        node_index.index :foo
      end

      def a_node
        double("A Node")
      end

      its(:index?, :foo) { should be_true }
      its(:index?, :bar) { should be_false }
      its(:index_type_for, :foo) { should == :exact }
      its(:index_type_for, :bar) { should be_nil }

      its(:index_type?, :exact) { should be_true }
      its(:index_type?, :fulltext) { should be_false }

      its(:field_types) { should include("foo")}

      describe "add_index" do
        it "returns false if there is no index on the property" do
          subject.add_index(double("A node"), :bar, "some value").should be_false
        end

        it "index the field if there is an index on the property" do
          pending "mocking needed"
          node = double("A node")
          subject.add_index(node, "foo", "some value").should be_true
        end

      end

    end
  end


end