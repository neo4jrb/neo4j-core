require 'spec_helper'

describe "Neo4j#query (cypher)", :type => :integration do

  before(:all) do
    new_tx
    @a = Neo4j::Node.new :name => 'a'
    @b = Neo4j::Node.new :name => 'b'
    @r = Neo4j::Relationship.new(:bar, @a, @b)
    finish_tx
  end

  describe "returning one node" do
    before(:all) do
      @query_result = Neo4j.query("START n=node(0) RETURN n")
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == 'n'
    end

    it "its first value is hash" do
      r = @query_result.to_a # can only loop once
      r.size.should == 1
      r.first.should include('n')
      r.first['n'].class.should == Neo4j::Node
      r.first['n'].neo_id.should == 0
    end
  end

  describe "returning one relationship" do
    before(:all) do
      @query_result = Neo4j.query("START n=relationship({rel}) RETURN n", 'rel' => @r.neo_id)
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == 'n'
    end

    it "its first value is hash" do
      r = @query_result.to_a
      r.size.should == 1
      r.first.should include('n')
      r.first['n'].class.should == Neo4j::Relationship
      r.first['n'].neo_id.should == @r.neo_id
    end
  end

  describe "returning several nodes" do
    before(:all) do
      @query_result = Neo4j.query("START n=node(#{@a.neo_id}, #{@b.neo_id}) RETURN n")
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == 'n'
    end

    it "its first value is hash" do
      r = @query_result.to_a # can only loop once
      r.size.should == 2
      r.first.should include('n')
      r[0]['n'].neo_id.should == @a.neo_id
      r[1]['n'].neo_id.should == @b.neo_id
    end
  end

  describe "a query with parameters" do
    it "should work" do
      @query_result = Neo4j.query('START n=node({a}) RETURN n', {'a' => @a.neo_id})
      @query_result.to_a.size.should == 1
    end

  end


  describe "a query with a lucene index" do

    class FooBarIndex
      extend Neo4j::Core::Index::ClassMethods
      include Neo4j::Core::Index

      self.node_indexer do
        index_names :exact => 'foobarindex_exact', :fulltext => 'foobarindex_fulltext'
        trigger_on :foobar => true
      end

      index :name
      index :desc, :type => :fulltext
    end


    before(:all) do
      Neo4j::Transaction.run do
        @foo = Neo4j::Node.new :foobar => true, :name => 'foo'
        @bar = Neo4j::Node.new :foobar => true, :name => 'bar'
        @andreas = Neo4j::Node.new :foobar => true, :name => 'andreas'
      end
    end

    it "can use the lucene index" do
      @query_result = Neo4j.query { lookup(FooBarIndex, "name", "bar").as(:n) }
      r = @query_result.to_a # can only loop once
      r.size.should == 1
      r.first['n'].wrapper.should == @bar
    end
  end
end
