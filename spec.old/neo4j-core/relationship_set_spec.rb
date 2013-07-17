require 'spec_helper'

describe Neo4j::Core::RelationshipSet do
  before(:each) do
    @set = Neo4j::Core::RelationshipSet.new
  end

  let(:node1) { MockNode.new}
  let(:node2) { MockNode.new}
  let(:node3) { MockNode.new}

  let(:rel) { MockRelationship.new(:relationship, node1, node2)}
  let(:rel1) { MockRelationship.new(:relationship, node1, node2)}
  let(:rel2) { MockRelationship.new(:relationship, node3, node2)}

  it "should return false contains for nonexistent entries" do
    @set.contains?(4,:foo).should be_false
  end

  it "should return true for registered entries" do
    @set.add(rel)
    @set.contains?(node2.getId(),:relationship).should be_true
  end

  it "should return list of nodes attached to an end node across relationships" do
    @set.add(rel1)
    @set.add(rel2)
    @set.relationships(node2.getId()).size.should == 2
    @set.relationships(node2.getId()).should include(rel1,rel2)
  end

  it "should return true if a relationship is contained" do
    @set.add(rel1)
    @set.contains_rel?(rel1).should be_true
    @set.contains_rel?(rel2).should be_false
  end
end