require 'spec_helper'

describe "Neo4j::Node", :type => :integration do

  describe "#new" do
    subject do
      node = Neo4j::Node.new
      finish_tx
      node
    end

    its(:neo_id) { should > 0 }
    its(:exist?) { should be_true }
    its(:class) { should == Neo4j::Node }
    it "can be loaded with Neo4j::Node.load" do
      id = subject.neo_id
      n = Neo4j::Node.load(id)
      n.neo_id.should == id
    end
  end

  describe "#del" do
    subject do
      node = Neo4j::Node.new
      finish_tx
      new_tx
      node.del
      finish_tx
      node
    end

    its(:exist?) { should be_false }

    it "Neo4j::Node.load returns nil" do
      Neo4j::Node.load(subject.neo_id).should == nil
    end

  end
end