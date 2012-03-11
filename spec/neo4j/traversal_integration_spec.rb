require 'spec_helper'

describe Neo4j::Node, :type => :integration do

  before(:all) do
    new_tx
    #
    #                f
    #                ^
    #              friends
    #                |
    #  a --friends-> b  --friends--> c
    #                |              ^
    #                |              |
    #                +--- work  -----+
    #                |
    #                +--- work  ---> d  --- work --> e
    @a = Neo4j::Node.new(:name => 'a')
    @b = Neo4j::Node.new(:name => 'b')
    @c = Neo4j::Node.new(:name => 'c')
    @d = Neo4j::Node.new(:name => 'd')
    @e = Neo4j::Node.new(:name => 'e')
    @f = Neo4j::Node.new(:name => 'f')
    @a.outgoing(:friends) << @b
    @b.outgoing(:friends) << @c
    @b.outgoing(:work) << @c
    @b.outgoing(:work) << @d
    @d.outgoing(:work) << @e
    @b.outgoing(:friends) << @f
    finish_tx
  end

  before(:each) do
    new_tx
  end

  after(:each) do
    finish_tx
  end


  describe "#depth_first, #breadth_first traversal order" do

    def connect(parent, child)
      Neo4j::Relationship.new(:child, parent, child)
    end

    before(:all) do
      # create a tree
      new_tx
      @t0 = Neo4j::Node.new(:name => 't0')
      @t1 = Neo4j::Node.new(:name => 't1')
      @t11 = Neo4j::Node.new(:name => 't11')
      @t111 = Neo4j::Node.new(:name => 't111')
      @t12 = Neo4j::Node.new(:name => 't12')
      @t2 = Neo4j::Node.new(:name => 't2')
      connect(@t0, @t2)
      connect(@t0, @t1)
      connect(@t1, @t11)
      connect(@t1, @t12)
      connect(@t11, @t111)
    end


    it "can traverse depth first, visiting each node before visiting " do
      order = @t0.outgoing(:child).depth_first(:pre).depth(:all).map { |n| n[:name] }
      order.should == ["t2", "t1", "t11", "t111", "t12"]
    end

    it "can traverse depth first, visiting each node after visiting its child nodes" do
      order = @t0.outgoing(:child).depth_first(:post).depth(:all).map { |n| n[:name] }
      order.should == ["t2", "t111", "t11", "t12", "t1"]
    end

    it "can traverse breadth first, visiting each node before visiting its child nodes" do
      order = @t0.outgoing(:child).breadth_first(:pre).depth(:all).to_a.map { |n| n[:name] }
      order.should == ["t2", "t1", "t11", "t12", "t111"]
    end

    it "can traverse breadth first, visiting each node after visiting its child nodes" do
      order = @t0.outgoing(:child).breadth_first(:post).depth(:all).to_a.map { |n| n[:name] }
      order.should == ["t111", "t11", "t12", "t2", "t1"]
    end
  end

  describe "#outgoing(:friends).paths" do
    it "returns paths objects" do
      paths = @a.outgoing(:friends).outgoing(:work).depth(:all).paths.to_a
      paths.each { |x| x.should be_kind_of(org.neo4j.graphdb.Path) }
      paths.size.should == 5
    end
  end

  describe "#outgoing(:friends).rels" do
    it "returns paths objects" do
      paths = @a.outgoing(:friends).outgoing(:work).depth(:all).rels.to_a
      paths.each { |x| x.should be_kind_of(org.neo4j.graphdb.Relationship) }
      paths.size.should == 5
    end
  end

  describe "#outgoing(:friends) << other_node" do
    it "creates an outgoing relationship of type :friends" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      a.outgoing(:friends) << other_node

      # then
      a.outgoing(:friends).first.should == other_node
    end

  end

  describe "#outgoing(:friends) << b << c" do
    it "#outgoing(:friends) << b << c creates an outgoing relationship of type :friends" do
      a = Neo4j::Node.new
      b = Neo4j::Node.new
      c = Neo4j::Node.new

      # when
      a.outgoing(:friends) << b << c

      # then
      a.outgoing(:friends).should include(b, c)
    end
  end

  describe "#incoming(:friends) << other_node " do
    it "should add an incoming relationship" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      a.incoming(:friends) << other_node

      # then
      a.incoming(:friends).first.should == other_node
    end
  end

  describe "#both(:friends) << other_node " do
    it "should raise an exception" do
      a = Neo4j::Node.new
      other_node = Neo4j::Node.new

      # when
      expect { a.both(:friends) << other_node }.to raise_error
    end
  end

  describe "#both" do
    it "returns all outgoing nodes of any type" do
      @b.both.should include(@a, @c, @d, @f)
      [*@b.both].size.should == 4
    end
  end

  describe "#incoming" do
    it "raise an exception - not supported" do
      lambda { @b.incoming.to_a }.should raise_error
    end
  end

  describe "#outgoing" do
    it "raise an exception - not supported" do
      lambda { @b.outgoing.to_a }.should raise_error
    end
  end

  describe "#outgoing(type)" do
    it "should only return outgoing nodes of the given type of depth one" do
      @b.outgoing(:work).should include(@c, @d)
      [*@b.outgoing(:work)].size.should == 2
    end

  end

  describe "#outgoing(type1).outgoing(type2) " do
    it "should return outgoing nodes of the given types" do
      nodes = @b.outgoing(:work).outgoing(:friends)
      nodes.should include(@c, @d, @f)
      nodes.count.should == 3
    end

  end


  describe "#outgoing(type).depth(4)" do
    it "should only return outgoing nodes of the given type and depth" do
      [*@b.outgoing(:work).depth(4)].size.should == 3
      @b.outgoing(:work).depth(4).should include(@c, @d, @e)
    end
  end

  describe "#outgoing(type).depth(4).include_start_node" do
    it "should also include the start node" do
      [*@b.outgoing(:work).depth(4).include_start_node].size.should == 4
      @b.outgoing(:work).depth(4).include_start_node.should include(@b, @c, @d, @e)
    end
  end

  describe "#outgoing(type).depth(:all)" do
    it "should traverse at any depth" do
      [*@b.outgoing(:work).depth(:all)].size.should == 3
      @b.outgoing(:work).depth(:all).should include(@c, @d, @e)
    end
  end

  describe "#incoming(type).depth(2)" do
    it "should only return outgoing nodes of the given type and depth" do
      [*@e.incoming(:work).depth(2)].size.should == 2
      @e.incoming(:work).depth(2).should include(@b, @d)
    end
  end

  describe "#incoming(type)" do
    it "should only return incoming nodes of the given type of depth one" do
      @c.incoming(:work).should include(@b)
      [*@c.incoming(:work)].size.should == 1
    end
  end

  describe "#both(type)" do
    it "should return both incoming and outgoing nodes of the given type of depth one" do
      @b.both(:friends).should include(@a, @c, @f)
      [*@b.both(:friends)].size.should == 3
    end
  end

  describe "#outgoing(:friends).incoming(:work)" do
    it "returns relationship of both relationship types" do
      nodes = [*@b.incoming(:friends).outgoing(:work)]
      nodes.should include(@a, @c, @d)
      nodes.should_not include(@b, @e)
    end
  end

  describe "#prune" do
    it "takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
      @b.outgoing(:friends).depth(4).prune { |path| path.should be_kind_of(Java::org.neo4j.graphdb.Path); false }.each {}
    end

    it "if provided block returns true the traversal will be 'cut off' that path" do
      [*@b.outgoing(:work).depth(4).prune { |path| true }].size.should == 2
      @b.outgoing(:work).depth(4).prune { |path| true }.should include(@c, @d)
    end
  end

  describe "#filter" do
    it "takes a block with parameter of type Java::org.neo4j.graphdb.Path" do
      @b.outgoing(:friends).depth(4).filter { |path| path.should be_kind_of(Java::org.neo4j.graphdb.Path); false }.each {}
    end

    it "if provided block returns true the node is not included" do
      nodes = [*@b.outgoing(:work).depth(4).filter { |path| path.length == 2 }]
      nodes.size.should == 1
      nodes.should include(@e)
    end

    it "accepts several filters which all must return true in order to include the node in the traversal result" do
      nodes = [*@b.outgoing(:work).depth(4).filter { |path| %w[c d].include?(path.end_node[:name]) }.
          filter { |path| %w[d e].include?(path.end_node[:name]) }]
      nodes.should include(@d)
      nodes.should_not include(@e)
      nodes.size.should == 1
    end
  end

  describe "#expand" do

    before(:each) do
      new_tx
      @x = Neo4j::Node.new(:name => 'x')
      @a = Neo4j::Node.new(:name => 'a')
      @b = Neo4j::Node.new(:name => 'b')
      @c = Neo4j::Node.new(:name => 'c')
      @d = Neo4j::Node.new(:name => 'd')
      @e = Neo4j::Node.new(:name => 'e')
      @f = Neo4j::Node.new(:name => 'f')
      @y = Neo4j::Node.new(:name => 'y')
    end

    it "can be used to select relationships based on relationship properties" do
      Neo4j::Relationship.new(:friends, @x, @a, :age => 1)
      Neo4j::Relationship.new(:friends, @x, @b, :age => 10)
      Neo4j::Relationship.new(:friends, @b, @c, :age => 1)
      Neo4j::Relationship.new(:friends, @b, @d, :age => 10)

      res = @x.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.depth(:all).to_a
      res.should include(@b, @d)
      res.size.should == 2
    end

    it "default is depth(1) traversals" do
      Neo4j::Relationship.new(:friends, @x, @a, :age => 1)
      Neo4j::Relationship.new(:friends, @x, @b, :age => 10)
      Neo4j::Relationship.new(:friends, @b, @c, :age => 1)
      Neo4j::Relationship.new(:friends, @b, @d, :age => 10)

      res = @x.expand { |n| n._rels.find_all { |r| r[:age] > 5 } }.to_a
      res.should include(@b)
      res.size.should == 1
    end

    it "returns nothing when expand returns an empty array" do
      Neo4j::Relationship.new(:friends, @x, @a)
      Neo4j::Relationship.new(:friends, @x, @b)
      Neo4j::Relationship.new(:friends, @b, @c)
      Neo4j::Relationship.new(:friends, @b, @d)
      res = @x.expand { |*| [] }.depth(:all)
      res.should be_empty
    end

  end

  describe "Neo4j::Node#eval_paths", :type => :transactional do
    before(:all) do
      new_tx
      @principal1 = Neo4j::Node.new(:name => 'principal1')
      @principal2 = Neo4j::Node.new(:name => 'principal2')
      @pet0 = Neo4j::Node.new(:name => 'pet0')
      @pet1 = Neo4j::Node.new(:name => 'pet1')
      @pet2 = Neo4j::Node.new(:name => 'pet2')
      @pet3 = Neo4j::Node.new(:name => 'pet3')

      @principal1.outgoing(:owns) << @pet1 << @pet3
      @pet0.outgoing(:descendant) << @pet1 << @pet2 << @pet3
      @principal2.outgoing(:owns) << @pet2
      finish_tx
    end

    it "#unique :node_path returns paths that is traversed more then once" do
      result = @pet0.eval_paths { |path| path.end_node == @principal1 ? :include_and_prune : :exclude_and_continue }.unique(:node_path).depth(:all).to_a
      result.size.should == 2
      result.should include(@principal1)
    end

    it "#unique :node_global returns paths that is traversed more then once" do
      result = @pet0.eval_paths { |path| path.end_node == @principal1 ? :include_and_prune : :exclude_and_continue }.unique(:node_global).depth(:all).to_a
      result.size.should == 1
      result.should include(@principal1)
    end

  end

end
