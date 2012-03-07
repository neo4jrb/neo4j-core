require 'spec_helper'

describe Neo4j::Core::Index::Indexer, :type => :mock_db do


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

  describe "node index" do
    let(:node_index) do
      clazz = double("Class")
      Neo4j::Core::Index::Indexer.new(node_config)
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
      its(:index_type, :foo) { should == :exact }
      its(:index_type, :bar) { should be_nil }

      its(:has_index_type?, :exact) { should be_true }
      its(:has_index_type?, :fulltext) { should be_false }

      describe "index" do
        it "by default ads an none numeric index" do
          subject.index(:my_index)

          subject.index?(:my_index).should be_true
          subject.has_index_type?(:exact).should be_true
          subject.has_index_type?(:fulltext).should be_false
          subject.trigger_on?('name' => 'bar').should be_true
          # TODO more clever trigger on ?
          node_config.numeric?('my_index').should be_false
        end

        it "can create a numeric index" do
          subject.index(:my_index, :numeric => true)
          subject.index?(:my_index).should be_true
          subject.has_index_type?(:exact).should be_true
          subject.has_index_type?(:fulltext).should be_false
          subject.trigger_on?('name' => 'bar').should be_true
          node_config.numeric?('my_index').should be_true
        end

      end

      describe "update_index_on" do
        context "when there is an index of the field" do
          before do
            subject.index(:my_field)
          end

          it "deletes and adds the index if it has a new and old value" do
            node = mock("a node")
            node_index_manager.should_receive(:remove).with(node, 'my_field', 'old_value')
            node_index_manager.should_receive(:add).with(node, 'my_field',  kind_of(Java::OrgNeo4jIndexLucene::ValueContext))
            subject.update_index_on(node, 'my_field', 'old_value', 'new_value')
          end

          it "only adds the index if it does not have an old value" do
            node = mock("a node")
            node_index_manager.should_receive(:add).with(node, 'my_field',  kind_of(Java::OrgNeo4jIndexLucene::ValueContext))
            subject.update_index_on(node, 'my_field', nil, 'new_value')
          end

          it "only remove the index if it does not have an new value" do
            node = mock("a node")
            node_index_manager.should_receive(:remove).with(node, 'my_field', 'old_value')
            subject.update_index_on(node, 'my_field', 'old_value', nil)
          end
        end

        context "when there is not an index on the field" do
          it "does not update the index" do
            subject.update_index_on(mock("a node"), 'my_field2', 'old_value', 'new_value')
          end
        end
      end

      describe "remove_index_on" do
        context "when there is an index of the field" do
          before do
            subject.index(:my_field)
            subject.index(:my_bla)
          end

          it "removes only property which has been declared" do
            node = mock("a node")
            node_index_manager.should_receive(:remove).with(node, 'my_field', 1)
            node_index_manager.should_receive(:remove).with(node, 'my_bla', 'foo')
            subject.remove_index_on(node, 'x' => 42, 'my_field' => 1, 'my_bla' => 'foo')
          end

        end

        context "when there is no index on the field" do
          it "removes only property which has been declared" do
            node = mock("a node")
            subject.remove_index_on(node, 'x' => 42, 'my_field' => 1, 'my_bla' => 'foo')
          end

        end

      end

      describe "add_index" do
        it "returns false if there is no index on the property" do
          subject.add_index(double("A node"), :bar, "some value").should be_false
        end

        it "index the field if there is an index on the property" do
          node = double("A node")
          node_index_manager.should_receive(:add).with(node, "foo", kind_of(Java::OrgNeo4jIndexLucene::ValueContext))
          subject.add_index(node, "foo", "some value")
        end

      end


      describe "rm_index" do
        it "returns false if there is no index on the property" do
          subject.rm_index(double("A node"), :bar, "some value").should be_false
        end

        it "removes the index" do
          node = double("A node")
          node_index_manager.should_receive(:remove).with(node, "foo", "some value")
          subject.rm_index(node, "foo", "some value")
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
          hits = double('hits')
          node_index_manager.should_receive(:query).and_return(hits)
          hits.should_receive(:close)
          hits.should_receive(:first).and_return("found_node")
          found_node = subject.find('name: andreas', :wrapped => false) { |h| h.first }
          found_node.should == 'found_node'
        end

        it "will automatically close the connection even if the block provided raises an exception" do
          hits = double('hits')
          node_index_manager.should_receive(:query).and_return(hits)
          hits.should_receive(:close)
          expect { subject.find('name: andreas', :wrapped => false) { |h| raise "oops" } }.to raise_error
        end

      end

    end
  end


end