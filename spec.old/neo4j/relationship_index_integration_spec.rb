require 'spec_helper'


describe "Neo4j::Relationship#index", :type => :integration do

  class MyRelIndex
    extend Neo4j::Core::Index::ClassMethods
    extend Forwardable
    include Neo4j::Core::Index
    attr_reader :_java_entity

    def_delegators :_java_entity, :[], :[]=

    def initialize(start_node, end_node, props = {})
      @_java_entity = self.class.new_rel start_node, end_node,(props)
    end

    self.rel_indexer do
      index_names :exact => 'my2index_exact', :fulltext => 'my2index_fulltext'
      trigger_on :myrelindex => true
    end

    def self.new_rel (start_node, end_node, props = {})
      Neo4j::Relationship.new(:family, start_node, end_node, props.merge(:myrelindex => true))
    end
  end

  before(:each) do
    MyRelIndex.index(:name) # default :exact
    MyRelIndex.index(:things)
    MyRelIndex.index(:age, :field_type => Fixnum) # default :exact
    MyRelIndex.index(:description, :type => :fulltext)
  end

  after(:each) do
    new_tx
    MyRelIndex.rm_index_config
    MyRelIndex.rm_index_type # delete all indexes
    finish_tx
  end

  let(:start_node) do
    Neo4j::Node.new(:name => 'start_node')
  end

  let(:end_node) do
    Neo4j::Node.new(:name => 'end_node')
  end

  describe "sorting" do
    it "#asc(:field) sorts the given field as strings in ascending order " do
      new_tx
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com'
      MyRelIndex.new_rel start_node, end_node, :name => 'gustav@gmail.com'
      MyRelIndex.new_rel start_node, end_node, :name => 'andreas@gmail.com'
      MyRelIndex.new_rel start_node, end_node, :name => 'orjan@gmail.com'

      new_tx
      result = MyRelIndex.find('name: *@gmail.com').asc(:name)

      # then
      emails = result.collect { |x| x[:name] }
      emails.should == %w[andreas@gmail.com gustav@gmail.com orjan@gmail.com pelle@gmail.com]
    end

    it "#desc(:field) sorts the given field as strings in desc order " do
      new_tx
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com'
      MyRelIndex.new_rel start_node, end_node, :name => 'gustav@gmail.com'
      MyRelIndex.new_rel start_node, end_node, :name => 'andreas@gmail.com'
      MyRelIndex.new_rel start_node, end_node, :name => 'zebbe@gmail.com'

      new_tx
      result = MyRelIndex.find('name: *@gmail.com').desc(:name)

      # then
      emails = result.collect { |x| x[:name] }
      emails.should == %w[zebbe@gmail.com pelle@gmail.com gustav@gmail.com andreas@gmail.com ]
    end

    it "#asc(:field1,field2) sorts the given field as strings in ascending order " do
      new_tx
      MyRelIndex.new_rel start_node, end_node, :name => 'zebbe@gmail.com', :age => 3
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 2
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 4
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 1
      MyRelIndex.new_rel start_node, end_node, :name => 'andreas@gmail.com', :age => 5

      new_tx

      result = MyRelIndex.find('name: *@gmail.com').asc(:name, :age)

      # then
      ages = result.collect { |x| x[:age] }
      ages.should == [5, 1, 2, 4, 3]
    end

    it "#asc(:field1).desc(:field2) sort the given field both ascending and descending orders" do
      new_tx

      MyRelIndex.new_rel start_node, end_node, :name => 'zebbe@gmail.com', :age => 3
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 2
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 4
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 1
      MyRelIndex.new_rel start_node, end_node, :name => 'andreas@gmail.com', :age => 5

      new_tx

      result = MyRelIndex.find('name: *@gmail.com').asc(:name).desc(:age)

      # then
      ages = result.collect { |x| x[:age] }
      ages.should == [5, 4, 2, 1, 3]
    end

  end


  describe "range queries" do

    it "range search with compound queries works" do
      new_tx
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle', :age => 3
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle', :age => 2
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle', :age => 4
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle', :age => 1
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle', :age => 5
      new_tx

      # when
      result = MyRelIndex.find('name: pelle').and(:age).between(2, 5)

      # then
      ages = result.collect { |x| x[:age] }
      ages.size.should == 2
      ages.should include(3, 4)
    end

    it "can do a range search" do
      new_tx
      MyRelIndex.new_rel start_node, end_node, :name => 'zebbe@gmail.com', :age => 3
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 2
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 4
      MyRelIndex.new_rel start_node, end_node, :name => 'pelle@gmail.com', :age => 1
      MyRelIndex.new_rel start_node, end_node, :name => 'andreas@gmail.com', :age => 5
      new_tx

      # when
      result = MyRelIndex.find(:age).between(2, 5)

      # then
      ages = result.collect { |x| x[:age] }
      ages.size.should == 2
      ages.should include(3, 4)
    end

  end

  describe "find" do
    it "can find several nodes with the same index" do
      new_tx

      thing1 = MyRelIndex.new_rel start_node, end_node, :name => 'thing'
      thing2 = MyRelIndex.new_rel start_node, end_node, :name => 'thing'
      thing3 = MyRelIndex.new_rel start_node, end_node, :name => 'thing'

      finish_tx

      MyRelIndex.find("name: thing", :wrapped => true).should include(thing1)
      MyRelIndex.find("name: thing", :wrapped => true).should include(thing2)
      MyRelIndex.find("name: thing", :wrapped => true).should include(thing3)
    end

  end

  it "#rm_index_config will make the index not updated when transaction finishes" do
    new_tx

    new_node = MyRelIndex.new_rel start_node, end_node, :name => 'andreas'
    MyRelIndex.find("name: andreas").first.should_not == new_node

    # when
    MyRelIndex.rm_index_config
    finish_tx

    # then
    MyRelIndex.find("name: andreas").first.should_not == new_node
    MyRelIndex.has_index_type?(:exact).should be_false
    MyRelIndex.index?(:name).should be_false

    # clean up
    MyRelIndex.index(:name)
  end

  describe "rm_index" do
    let!(:my_node) do
      new_tx
      new_node = MyRelIndex.new(start_node, end_node, :name => 'abcdef')
      new_node.add_index(:name)
      new_node.add_index(:things, 'aa')
      new_node.add_index(:things, 'bb')
      new_node.add_index(:things, 'cc')
      finish_tx
      new_node._java_entity
    end

    it "remove entity index" do
      MyRelIndex.find('name: abcdef').first.should == my_node
      MyRelIndex.find('things: aa').first.should == my_node
      MyRelIndex.find('things: cc').first.should == my_node
      MyRelIndex.find('things: qd').first.should_not == my_node
    end

    it "removes entity index and property key" do
      new_tx

      new_node = MyRelIndex.new(start_node, end_node)
      new_node[:name] = 'Kalle Kula'
      new_node.add_index(:name)

      # when
      new_node.rm_index(:name)

      new_node[:name] = 'lala'
      new_node.add_index(:name)

      # then
      MyRelIndex.find('name: lala').first.should == new_node._java_entity
      MyRelIndex.find('name: "Kalle Kula"').first.should_not == new_node._java_entity
    end
  end

  describe "update index when a node changes" do
    it "updates an index automatically when a property changes" do
      new_tx

      new_node = MyRelIndex.new_rel start_node, end_node, :name => 'Kalle Kula'

      new_tx
      MyRelIndex.find('name: "Kalle Kula"').first.should == new_node
      MyRelIndex.find('name: lala').first.should_not == new_node

      new_node[:name] = 'lala'

      new_tx

      # then
      result = MyRelIndex.find('name: lala').first
      MyRelIndex.find('name: lala').first.should == new_node
      MyRelIndex.find('name: "Kalle Kula"').first.should_not == new_node
    end

    it "deleting an indexed property should not be found" do
      new_tx

      new_node = MyRelIndex.new_rel start_node, end_node, :name => 'andreas'
      new_tx

      MyRelIndex.find('name: andreas').first.should == new_node

      # when deleting an indexed property
      new_node[:name] = nil
      new_tx
      MyRelIndex.find('name: andreas').first.should_not == new_node
    end

    it "deleting the node deletes its index" do
      new_tx

      new_node = MyRelIndex.new_rel start_node, end_node, :name => 'hejhopp'
      new_tx
      MyRelIndex.find('name: hejhopp').first.should == new_node

      # when
      new_node.del
      finish_tx
      # then
      MyRelIndex.find('name: hejhopp').first.should_not == new_node
    end

    it "both deleting a property and deleting the node should work" do
      new_tx

      new_node = MyRelIndex.new_rel start_node, end_node, :name => 'andreas', :age => 21
      new_tx
      MyRelIndex.find('name: andreas').first.should == new_node

      # when
      new_node[:name] = nil
      new_node[:age] = nil
      new_node.del
      finish_tx

      # then
      MyRelIndex.find('name: andreas').first.should_not == new_node
    end

  end

  describe "add_index" do
    it "should create index on a node" do
      new_tx

      new_node = MyRelIndex.new(start_node, end_node)
      new_node[:name] = 'andreas'

      # when
      new_node.add_index(:name)

      # then
      MyRelIndex.find("name: andreas", :wrapped => false).get_single.should == new_node._java_entity
    end


    it "should create index on a node with a given type (e.g. fulltext)" do
      new_tx

      new_node = MyRelIndex.new(start_node, end_node)
      new_node[:description] = 'hej'

      # when
      new_node.add_index(:description)

      # then
      MyRelIndex.find('description: "hej"', :type => :fulltext, :wrapped => false).get_single.should == new_node._java_entity
    end

    it "does not remove old index when calling add_index twice" do
      new_tx

      new_node = MyRelIndex.new(start_node, end_node)
      new_node[:name] = 'Kalle Kula'
      new_node.add_index(:name)

      # when
      new_node[:name] = 'lala'
      new_node.add_index(:name)

      # then
      MyRelIndex.find('name: lala').first.should == new_node._java_entity
      MyRelIndex.find('name: "Kalle Kula"').first.should == new_node._java_entity
    end


  end
end
