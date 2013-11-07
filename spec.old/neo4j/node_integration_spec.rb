require 'spec_helper'

describe Neo4j::Node, :type => :integration do

  describe "#new" do
    subject do
      new_tx
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
    its("props.size") { should == 1 }
    its(:props) { should include('_neo_id') }
  end

  describe "#del" do
    context "before commit" do
      subject do
        new_tx
        node = Neo4j::Node.new
        new_tx
        node.del
        node
      end

      its(:exist?) { should be_false }

      it "will load it with Neo4j::Node.load" do
        Neo4j::Node.load(subject.neo_id).should == subject
      end

    end

    context "after commit" do
      subject do
        new_tx
        node = Neo4j::Node.new
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
end