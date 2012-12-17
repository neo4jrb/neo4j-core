require 'spec_helper'

describe "Neo4j#query (cypher)", :type => :integration do

  before(:all) do
    new_tx
    @a = Neo4j::Node.new :name => 'a'
    @b = Neo4j::Node.new :name => 'b'
    @r = Neo4j::Relationship.new(:bar, @a, @b)
    finish_tx
  end

  describe "returning one node: node(0).as(:n)" do
    before(:all) do
      @query_result = Neo4j.query{node(0).as(:n)}
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == :n
    end

    it "its first value is hash" do
      r = @query_result.to_a # can only loop once
      r.size.should == 1
      r.first.should include(:n)
      r.first[:n].class.should == Neo4j::Node
      r.first[:n].neo_id.should == 0
    end
  end

  describe 'return one property' do
    before(:all) do
      n1 = @a.neo_id
      n2 = @b.neo_id
      @query_result = Neo4j.query{node(n1, n2)[:name].desc}
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == :"v1.name"
    end

    it "its first value is hash" do
      r = @query_result.to_a # can only loop once
      r.size.should == 2
      r.first.should include(:"v1.name")
      r.first[:"v1.name"].should == 'b'
      r[1][:"v1.name"].should == 'a'
    end

  end


  describe "returning one relationship: {|r| rel(r).as(:n)}" do
    before(:all) do
      @query_result = Neo4j.query(@r){|r| r.as(:n)}
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == :n
    end

    it "its first value is hash" do
      r = @query_result.to_a
      r.size.should == 1
      r.first.should include(:n)
      r.first[:n].class.should == Neo4j::Relationship
      r.first[:n].neo_id.should == @r.neo_id
    end
  end

  describe "returning several nodes" do
    before(:all) do
      @query_result = Neo4j.query([@a, @b]){|n| n.as(:n)}
    end

    it "has one column" do
      @query_result.columns.size.should == 1
      @query_result.columns.first.should == :n
    end

    it "its first value is hash" do
      r = @query_result.to_a # can only loop once
      r.size.should == 2
      r.first.should include(:n)
      r[0][:n].neo_id.should == @a.neo_id
      r[1][:n].neo_id.should == @b.neo_id
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
      r.first[:n].wrapper.should == @bar
    end
  end

  describe "issue #208, START n=node(*) RETURN n" do
    it 'should not raise an exception' do
      Neo4j._query("START n=node(*) RETURN n").first
    end
  end
end
