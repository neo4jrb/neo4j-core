require 'spec_helper'

describe "Neo4j Cypher Traversal", :type => :integration do
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
      @a.outgoing(:foo).query.should include(@b, @c)
    end
  end

  describe "b.outgoing(:foo).outgoing(:bar).query" do
    it "returns all outgoing nodes of rel type foo and bar" do
      pending "TODO"
      @b.outgoing(:foo).outgoing(:bar).query.to_a.size.should == 3
      @b.outgoing(:foo).outgoing(:bar).query.should include(@c, @d, @e)
    end
  end

  it "Some Tests" do
    @a.outgoing(:foo).to_a.should include(@b,@c)
    #result = a.outgoing(:foo).query{|x| x[:val] == 2}.to_a#.should include(b,c)
    #result.size.should == 1
    #result.should include(b)
    #
    #result = a.outgoing(:foo).query{|x| b=node(:b); x > ':bar' > b; b}
    result = @a.outgoing(:foo).query{|x| b=node(:b); x > ':bar' > b; b}
    result.each do |x|
      puts "X=#{x.props.inspect}"
    end

    result = @a.outgoing(:foo).query{|x| f = x.outgoing(:bar); f2 = f.incoming(:bar); where f[:val] < 123123; f.distinct}
    result.each do |x|
      puts "X=#{x.props.inspect}"
    end

  end

end
