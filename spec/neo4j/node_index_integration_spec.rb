require 'spec_helper'


describe "Neo4j::Node#index", :type => :integration do

  class MyIndex
    extend Neo4j::Core::Index::ClassMethods
    extend Forwardable
    include Neo4j::Core::Index
    attr_reader :java_entity

    def_delegators :java_entity, :[], :[]=

    def initialize(props = {})
      @java_entity = self.class.new_node(props)
    end

    self.node_indexer do
      index_names :exact => 'myindex_exact', :fulltext => 'myindex_fulltext'
      trigger_on :myindex => true
    end

    def self.new_node (props = {})
      Neo4j::Node.new(props.merge(:myindex => true))
    end
  end

  before(:each) do
    MyIndex.index(:name) # default :exact
    MyIndex.index(:things)
    MyIndex.index(:age, :field_type => Fixnum) # default :exact
    MyIndex.index(:wheels, :field_type => Fixnum)
    MyIndex.index(:description, :type => :fulltext)
  end

  after(:each) do
    new_tx
    MyIndex.rm_index_config
    MyIndex.rm_index_type # delete all indexes
    finish_tx
  end


  describe "Neo4j::NodeIndex" do
    before(:all) do
      Neo4j::Node.trigger_on(:typex => 'MyTypeX')
      Neo4j::Node.index(:name)
    end

    after(:all) do
      Neo4j::Node.rm_index_config
      Neo4j::Node.rm_index_type
    end

    it "will be triggered" do
      new_tx
      a = Neo4j::Node.new(:name => 'andreas', :typex => 'MyTypeX')
      Neo4j::Node.find(:name => 'andreas').first.should be_nil
      finish_tx
      Neo4j::Node.find(:name => 'andreas').first.should == a
    end

    it "can by updated with the add_index method" do
      new_tx
      foo = Neo4j::Node.new(:name => 'foo')
      foo.add_index(:name)
      Neo4j::Node.find(:name => 'foo').first.should == foo
    end

    it "can not allow index on none indexed fields" do
      new_tx
      surname = Neo4j::Node.new(:surname => 'bar')
      surname.add_index(:surname)
      # TODO, either throw an Exception above or allow this
      lambda{Neo4j::Node.find(:surname => 'bar').first}.should raise_error
    end
  end

  describe "Neo4j::RelationshipIndex" do
    before(:all) do
      Neo4j::Relationship.trigger_on(:typey => 123)
      Neo4j::Relationship.index(:name)
    end

    it "will be triggered" do
      new_tx
      a = Neo4j::Relationship.new(:friends, Neo4j::Node.new, Neo4j::Node.new, :typey => 123, :name => 'kalle')
      Neo4j::Relationship.find(:name => 'kalle').first.should be_nil
      finish_tx
      Neo4j::Relationship.find(:name => 'kalle').first.should == a
    end
  end

  describe "index on array" do
    it "is possible to index arrays" do
      new_tx
      node = MyIndex.new_node :things => %w[aaa bbb ccc ddd efg qwe]
      finish_tx
      MyIndex.find('things: aaa').first.should == node
      MyIndex.find('things: bbb').first.should == node
      MyIndex.find('things: qwe').first.should == node
    end

    it "is updated when one item changes" do
      new_tx
      node = MyIndex.new_node :things => %w[aaa bbb ccc ddd efg qwe]
      finish_tx
      MyIndex.find('things: aaa').first.should == node
      MyIndex.find('things: bbb').first.should == node
      MyIndex.find('things: qwe').first.should == node
      new_tx
      node[:things] = %w[bbb ewq qwe]
      finish_tx
      MyIndex.find('things: aaa').should be_empty
      MyIndex.find('things: ewq').first.should == node
      MyIndex.find('things: qwe').first.should == node
    end

    it "index is deleted when node deleted" do
      new_tx
      node = MyIndex.new_node :things => %w[aaa bbb ccc ddd efg qwe]
      new_tx
      node.del
      finish_tx
      MyIndex.find('things: aaa').should be_empty
    end

    it "support array of Fixnum" do
      new_tx
      node = MyIndex.new_node(:age => [8,92,2])
      finish_tx
      MyIndex.find(:age => 8).first.should == node
      MyIndex.find(:age => 9).should be_empty
      MyIndex.find(:age => 2).first.should == node
    end
  end

  describe "sorting" do
    it "#asc(:field) sorts the given field as strings in ascending order " do
      new_tx
      MyIndex.new_node :name => 'pelle@gmail.com'
      MyIndex.new_node :name => 'gustav@gmail.com'
      MyIndex.new_node :name => 'andreas@gmail.com'
      MyIndex.new_node :name => 'orjan@gmail.com'

      new_tx
      result = MyIndex.find('name: *@gmail.com').asc(:name)

      # then
      emails = result.collect { |x| x[:name] }
      emails.should == %w[andreas@gmail.com gustav@gmail.com orjan@gmail.com pelle@gmail.com]
    end

    it "#desc(:field) sorts the given field as strings in desc order " do
      new_tx
      MyIndex.new_node :name => 'pelle@gmail.com'
      MyIndex.new_node :name => 'gustav@gmail.com'
      MyIndex.new_node :name => 'andreas@gmail.com'
      MyIndex.new_node :name => 'zebbe@gmail.com'

      new_tx
      result = MyIndex.find('name: *@gmail.com').desc(:name)

      # then
      emails = result.collect { |x| x[:name] }
      emails.should == %w[zebbe@gmail.com pelle@gmail.com gustav@gmail.com andreas@gmail.com ]
    end

    it "#asc(:field1,field2) sorts the given field as strings in ascending order " do
      new_tx
      MyIndex.new_node :name => 'zebbe@gmail.com', :age => 3
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 2
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 4
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 1
      MyIndex.new_node :name => 'andreas@gmail.com', :age => 5

      new_tx

      result = MyIndex.find('name: *@gmail.com').asc(:name, :age)

      # then
      ages = result.collect { |x| x[:age] }
      ages.should == [5, 1, 2, 4, 3]
    end

    it "#asc(:field1).desc(:field2) sort the given field both ascending and descending orders" do
      new_tx

      MyIndex.new_node :name => 'zebbe@gmail.com', :age => 3
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 2
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 4
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 1
      MyIndex.new_node :name => 'andreas@gmail.com', :age => 5

      new_tx

      result = MyIndex.find('name: *@gmail.com').asc(:name).desc(:age)

      # then
      ages = result.collect { |x| x[:age] }
      ages.should == [5, 4, 2, 1, 3]
    end

  end


  describe "range queries" do

    it "range search with compound queries works" do
      new_tx
      MyIndex.new_node :name => 'pelle', :age => 3
      MyIndex.new_node :name => 'pelle', :age => 2
      MyIndex.new_node :name => 'pelle', :age => 4
      MyIndex.new_node :name => 'pelle', :age => 1
      MyIndex.new_node :name => 'pelle', :age => 5
      new_tx

      # when
      result = MyIndex.find('name: pelle').and(:age).between(2, 5)

      # then
      ages = result.collect { |x| x[:age] }
      ages.size.should == 2
      ages.should include(3, 4)
    end

    it "can do a range search" do
      new_tx
      MyIndex.new_node :name => 'zebbe@gmail.com', :age => 3
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 2
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 4
      MyIndex.new_node :name => 'pelle@gmail.com', :age => 1
      MyIndex.new_node :name => 'andreas@gmail.com', :age => 5
      new_tx

      # when
      result = MyIndex.find(:age).between(2, 5)

      # then
      ages = result.collect { |x| x[:age] }
      ages.size.should == 2
      ages.should include(3, 4)
    end

  end

  describe "find(Hash)" do
    before(:each) do
      new_tx
      @thing1 = MyIndex.new_node :name => 'thing', :wheels => 2
      @thing2 = MyIndex.new_node :name => 'thing', :wheels => 4
      @thing3 = MyIndex.new_node :name => 'bla', :wheels => 8
      finish_tx
    end
    let(:thing1) { @thing1 }
    let(:thing2) { @thing2 }
    let(:thing3) { @thing3 }

    it "can find using a hash AND values" do
      MyIndex.find("name: bla").first.should == thing3
      MyIndex.find(:name => "bla").first.should == thing3
      MyIndex.find(:wheels => 4).first.should == thing2
      MyIndex.find(:name => 'thing', :wheels => 4).first.should == thing2
      MyIndex.find(:name => 'thing', :wheels => 5).should be_empty
      MyIndex.find(:name => 'thing1', :wheels => 4).should be_empty
    end

    describe "compound AND queries" do

      it "can combine OR queries" do
        MyIndex.find(:name => 'asd').or(:wheels => 8).first.should == thing3
        MyIndex.find(:name => 'bla').or(:wheels => 7).first.should == thing3
      end

      it "can combine AND queries" do
        MyIndex.find("name: 'asd'").and(:wheels => 8).should be_empty
        MyIndex.find(:name => 'asd').and(:wheels => 8).should be_empty
        MyIndex.find(:name => 'bla').and(:wheels => 7).should be_empty
        MyIndex.find(:name => 'bla').and(:wheels => 8).first.should == thing3
      end

      it "can combine AND range queries" do
        MyIndex.find(:name => 'thing').and(:wheels => (9..15)).should be_empty
        MyIndex.find(:name => 'thing').and(:wheels => (0..9)).size.should == 2
        MyIndex.find(:name => 'thing').and(:wheels => (0..9)).should include(thing1, thing2)
      end

      it "can combine NOT queries" do
        MyIndex.find(:name => 'asd').not(:wheels => 8).should be_empty
        MyIndex.find(:name => 'bla').not(:wheels => 7).first.should == thing3
        MyIndex.find(:name => 'bla').not(:wheels => 8).should be_empty
      end

    end

  end
  describe "find(String)" do
    it "can find several nodes with the same index" do
      new_tx
      thing1 = MyIndex.new_node :name => 'thing'
      thing2 = MyIndex.new_node :name => 'thing'
      thing3 = MyIndex.new_node :name => 'thing'
      finish_tx

      MyIndex.find("name: thing", :wrapped => true).should include(thing1)
      MyIndex.find("name: thing", :wrapped => true).should include(thing2)
      MyIndex.find("name: thing", :wrapped => true).should include(thing3)
    end

  end

  it "#rm_index_config will make the index not updated when transaction finishes" do
    new_tx

    new_node = MyIndex.new_node :name => 'andreas'
    MyIndex.find("name: andreas").first.should_not == new_node

    # when
    MyIndex.rm_index_config
    finish_tx

    # then
    MyIndex.find("name: andreas").first.should_not == new_node
    MyIndex.has_index_type?(:exact).should be_false
    MyIndex.index?(:name).should be_false

    # clean up
    MyIndex.index(:name)
  end

  describe "rm_index" do
    let!(:my_node) do
      new_tx
      new_node = MyIndex.new(:name => 'abcdef')
      new_node.add_index(:name)
      new_node.add_index(:things, 'aa')
      new_node.add_index(:things, 'bb')
      new_node.add_index(:things, 'cc')
      finish_tx
      new_node.java_entity
    end

    it "remove entity index" do
      MyIndex.find('name: abcdef').first.should == my_node
      MyIndex.find('things: aa').first.should == my_node
      MyIndex.find('things: cc').first.should == my_node
      MyIndex.find('things: qd').first.should_not == my_node
    end

    it "removes entity index and property key" do
      new_tx

      new_node = MyIndex.new
      new_node[:name] = 'Kalle Kula'
      new_node.add_index(:name)

      # when
      new_node.rm_index(:name)

      new_node[:name] = 'lala'
      new_node.add_index(:name)

      # then
      MyIndex.find('name: lala').first.should == new_node.java_entity
      MyIndex.find('name: "Kalle Kula"').first.should_not == new_node.java_entity
    end
  end

  describe "update index when a node changes" do
    it "updates an index automatically when a property changes" do
      new_tx

      new_node = MyIndex.new_node(:name => 'Kalle Kula')

      new_tx
      MyIndex.find('name: "Kalle Kula"').first.should == new_node
      MyIndex.find('name: lala').first.should_not == new_node

      new_node[:name] = 'lala'

      new_tx

      # then
      result = MyIndex.find('name: lala').first
      MyIndex.find('name: lala').first.should == new_node
      MyIndex.find('name: "Kalle Kula"').first.should_not == new_node
    end

    it "deleting an indexed property should not be found" do
      new_tx

      new_node = MyIndex.new_node :name => 'andreas'
      new_tx

      MyIndex.find('name: andreas').first.should == new_node

      # when deleting an indexed property
      new_node[:name] = nil
      new_tx
      MyIndex.find('name: andreas').first.should_not == new_node
    end

    it "deleting the node deletes its index" do
      new_tx

      new_node = MyIndex.new_node :name => 'hejhopp'
      new_tx
      MyIndex.find('name: hejhopp').first.should == new_node

      # when
      new_node.del
      finish_tx
      # then
      MyIndex.find('name: hejhopp').first.should_not == new_node
    end

    it "both deleting a property and deleting the node should work" do
      new_tx

      new_node = MyIndex.new_node :name => 'andreas', :age => 21
      new_tx
      MyIndex.find('name: andreas').first.should == new_node

      # when
      new_node[:name] = nil
      new_node[:age] = nil
      new_node.del
      finish_tx

      # then
      MyIndex.find('name: andreas').first.should_not == new_node
    end

  end

  describe "add_index" do
    it "should create index on a node" do
      new_tx

      new_node = MyIndex.new
      new_node[:name] = 'andreas'

      # when
      new_node.add_index(:name)

      # then
      MyIndex.find("name: andreas", :wrapped => false).get_single.should == new_node.java_entity
    end


    it "should create index on a node with a given type (e.g. fulltext)" do
      new_tx

      new_node = MyIndex.new
      new_node[:description] = 'hej'

      # when
      new_node.add_index(:description)

      # then
      MyIndex.find('description: "hej"', :type => :fulltext, :wrapped => false).get_single.should == new_node.java_entity
      MyIndex.find({:description => "hej"}, :type => :fulltext).first.should == new_node.java_entity
    end

    it "does not remove old index when calling add_index twice" do
      new_tx

      new_node = MyIndex.new
      new_node[:name] = 'Kalle Kula'
      new_node.add_index(:name)

      # when
      new_node[:name] = 'lala'
      new_node.add_index(:name)

      # then
      MyIndex.find('name: lala').first.should == new_node.java_entity
      MyIndex.find('name: "Kalle Kula"').first.should == new_node.java_entity
    end


  end
end
