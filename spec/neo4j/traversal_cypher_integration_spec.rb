require 'spec_helper'

describe "Neo4j Traversal query method", :type => :integration do
  before(:all) do
    new_tx
    @a = Neo4j::Node.new(:name => 'a', :val => 1)
    @b = Neo4j::Node.new(:name => 'b', :val => 2)
    @c = Neo4j::Node.new(:name => 'c', :val => 3)
    @d = Neo4j::Node.new(:name => 'd', :val => 4)
    @e = Neo4j::Node.new(:name => 'e', :val => 5)

    @a.outgoing(:foo) << @b << @c
    @b.outgoing(:foo) << @c
    @b.outgoing(:bar) << @d << @e
    @c.outgoing(:bar) << @e
    finish_tx
  end

  describe "a.outgoing(:foo).query" do
    it "returns all outgoing nodes of rel type foo" do
      @a.outgoing(:foo).query.to_a.size.should == 2
      puts "RESULT ___________ #{@a.outgoing(:foo).query}"
      @a.outgoing(:foo).query.should include(@b, @c)
    end
  end

  describe "b.outgoing(:foo).outgoing(:bar).query" do
    it "returns all outgoing nodes of rel type foo and bar" do
      @b.outgoing(:foo).outgoing(:bar).query.to_a.size.should == 3
      @b.outgoing(:foo).outgoing(:bar).query.should include(@c, @d, @e)
    end
  end


  describe "a where clause with a hash query param" do
    it ".query(:name => 'b') will translate to a WHERE and cypher query" do
      @a.outgoing(:foo).query(:name => 'b').first.should == @b
    end
  end

  describe "a match clause in the query block" do

    #it "allows > match clause" do
    #  result = @a.outgoing(:foo).query { |x| b=node(:b); x > ':bar' > b; b }
    #  result.count.should == 3
    #end

    it "allows a outgoing/incoming clause in the query block" do
      result = @a.outgoing(:foo).query { |x| f = x.as(:x).outgoing(:bar).as(:f); f2 = f.incoming(:bar).as(:f2); ret f.distinct }
      puts "RESULT #{result.to_s}"
      result.count.should == 1
    end

    it "allows a both clause in the query block" do
      result = @a.outgoing(:foo).query { |x| f = x.both(:bar); f.distinct }
      result.count.should == 2
    end

    it "allows a where clause in the query block" do
      result = @a.outgoing(:foo).query { |x| x[:val] == 2 }.to_a
      result.count.should == 1
      result.first[:val].should == 2
    end

  end
end
