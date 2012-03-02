require 'spec_helper'

describe Neo4j::Core::Index::Indexer, :type => :mock_db do


  describe "node index" do
    let(:node_index) do
      clazz = double("Class")
      Neo4j::Core::Index::Indexer.new(clazz, :node)
    end

    subject { node_index }
    its(:to_s) { should be_a(String) }

    context "when indexed :foo" do
      let!(:node_index_manager) do
        index_manager = mock("Node Index Manager")
        Neo4j.db.lucene.stub!(:for_nodes).and_return(index_manager)
        index_manager
      end

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
          node = double("A node")
          node_index_manager.should_receive(:add).with(node, "foo", kind_of(Java::OrgNeo4jIndexLucene::ValueContext))
          subject.add_index(node, "foo", "some value").should be_true
        end

      end


      describe "rm_index" do
        it "returns false if there is no index on the property" do
          subject.rm_index(double("A node"), :bar, "some value").should be_false
        end

        it "removes the index" do
          node = double("A node")
          node_index_manager.should_receive(:remove).with(node, "foo", "some value")
          subject.rm_index(node, "foo", "some value").should be_true
        end

      end

      describe "find" do
        it "find('name: kalle') returns a LuceneQuery object" do
          subject.find('name: kalle').should be_kind_of(Neo4j::Core::Index::LuceneQuery)
        end

        it "find('name: kalle', :wrapped => false) returns a LuceneQuery object" do
          node_index_manager.should_receive(:query).with("name: kalle")
          subject.find('name: kalle', :wrapped => false)
        end


        it "find(:name => 'kalle') returns a LuceneQuery object" do
          result = subject.find(:name => 'kalle')
          result.should be_kind_of(Neo4j::Core::Index::LuceneQuery)
          result.query.should == {:name => 'kalle'}
        end


        it "find(:name => 'kalle', :sort => {:name => :desc}) returns a LuceneQuery object with sorting" do
          result = subject.find(:name => 'kalle', :sort => {:name => :desc})
          result.should be_kind_of(Neo4j::Core::Index::LuceneQuery)
          result.query.should == {:name => 'kalle'}
          result.order.should == {:name => true}
        end

        it "find(:conditions => {:name => 'kalle'}) also works" do
          result = subject.find(:conditions => {:name => 'kalle'})
          result.should be_kind_of(Neo4j::Core::Index::LuceneQuery)
          result.query.should == {:name => 'kalle'}
        end


        it "will automatically close the connection if a block was provided with the find method" do
          hits        = double('hits')
          node_index_manager.should_receive(:query).and_return(hits)
          hits.should_receive(:close)
          hits.should_receive(:first).and_return("found_node")
          found_node  = subject.find('name: andreas', :wrapped => false) { |h| h.first }
          found_node.should == 'found_node'
        end

        it "will automatically close the connection even if the block provided raises an exception" do
          hits        = double('hits')
          node_index_manager.should_receive(:query).and_return(hits)
          hits.should_receive(:close)
          expect { subject.find('name: andreas', :wrapped => false) { |h| raise "oops" } }.to raise_error
        end

      end

    end
  end


end