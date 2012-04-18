require 'spec_helper'

describe Neo4j::Relationship, :type => :integration do
  let(:node_a) do
    Neo4j::Node.new(:name => 'a')
  end

  let(:node_b) do
    Neo4j::Node.new(:name => 'b')
  end


  describe "#new(:friends, node_a, node_b)" do
    subject do
      new_tx
      rel = Neo4j::Relationship.new(:friends, node_a, node_b)
      finish_tx
      rel
    end

    it '#java_class == org.neo4j.kernel.impl.core.RelationshipProxy' do
      subject.java_class.to_s == "org.neo4j.kernel.impl.core.RelationshipProxy"
    end

    its(:neo_id) { should be_a(Fixnum) }
    its(:class) { should == Neo4j::Relationship }
    its(:rel_type) { should == :friends }
    its(:exist?) { should be_true }
    its(:wrapper) { should == subject }
    its(:_java_rel) { should == subject }
    its(:java_entity) { should == subject }
    its(:end_node) { should == node_b }
    its(:start_node) { should == node_a }
    its(:_end_node) { should == node_b }
    its(:_start_node) { should == node_a }
    its("props.size") { should == 1}
    its(:props) { should include('_neo_id')}

    it("other_node(node_a) == node_b") { subject.other_node(node_a).should == node_b }
    it("other_node(node_b) == node_a") { subject.other_node(node_b).should == node_a }
    it("_other_node(node_a) == node_b") { subject._other_node(node_a).should == node_b }
    it("_other_node(node_b) == node_a") { subject._other_node(node_b).should == node_a }
    it "[]= sets a property and [] reads a property" do
      rel = subject
      new_tx
      rel[:thingy] = 123
      finish_tx
      rel[:thingy].should == 123
    end

    describe "update" do
      it "updates the property given the hash" do
        rel = subject
        new_tx
        rel.update(:age => 2, :foo => 'bar')
        rel[:age].should == 2
        rel[:foo].should == 'bar'
      end
    end
  end

  describe "#new(:friends, node_a, node_b, :name => 'kalle')" do
    subject do
      new_tx
      rel = Neo4j::Relationship.new(:friends, node_a, node_b, :name => 'kalle')
      finish_tx
      rel
    end

    its([:name]) { should == 'kalle' }
    its(:property?, :name) { should be_true }
    it "removed the property if set to nil" do
      rel = subject
      new_tx
      rel[:name] = nil
      rel.property?(:name).should be_false
      rel[:name].should be_nil
      finish_tx
      rel.property?(:name).should be_false
      rel[:name].should be_nil
    end

    it "can be found using the start_node and end_node #rels method" do
      start_node = subject.start_node
      start_node.rels.should include(subject)
      end_node = subject.end_node
      end_node.rels(:incoming, :friends).should include(subject)
    end

    it "can be found using the rel method on the start and end node" do
      start_node = subject.start_node
      end_node = subject.end_node

      start_node.rel(:outgoing, :friends).should == subject
      start_node.rel(:outgoing, :friends).end_node.should == end_node

      end_node.rel(:incoming, :friends).should == subject
      end_node.rel(:incoming, :friends).start_node.should == start_node

      start_node.rels(:outgoing, :friends).to_a.should == [subject]
      end_node.rels(:incoming, :friends).to_a.should == [subject]
    end
  end

  describe "#del" do
    context "before commit" do
      subject do
        new_tx
        rel = Neo4j::Relationship.new(:friends, node_a, node_b)
        new_tx
        rel.del
        rel
      end

      its(:exist?) { should be_false }
    end

    context "after commit" do
      subject do
        new_tx
        rel = Neo4j::Relationship.new(:friends, node_a, node_b)
        new_tx
        rel.del
        finish_tx
        rel
      end

      its(:exist?) { should be_false }
    end
  end

  describe "#load" do
    let(:a_rel) do
      new_tx
      rel = Neo4j::Relationship.new(:friends, node_a, node_b)
      finish_tx
      rel
    end

    it "should load existing relationship" do
      Neo4j::Relationship.load(a_rel.neo_id).should == a_rel
    end

    it "should return nil if it does not exist" do
      Neo4j::Relationship.load(-9999).should be_nil
    end

  end
end
