require 'spec_helper'

describe Neo4j::Core::Rels::Traverser do

  before do
    Neo4j::Core::ToJava.stub(:type_to_java) { |x| x }
    Neo4j::Core::ToJava.stub(:dir_to_java) { |x| x }
  end

  let(:a_node) { MockNode.new }

  context "a node with two relationships" do
    subject { Neo4j::Core::Rels::Traverser.new(a_node, [:foo, :bar]) }

    let(:rel_1) { MockRelationship.new }
    let(:rel_2) { MockRelationship.new }

    before do
      java_array = Java::java.util.ArrayList.new
      java_array += [rel_1, rel_2]
      subject.stub(:iterator) { java_array.iterator }
    end

    its(:count) { should == 2 }
    its(:size) { should == 2 }
    its(:to_a) { should == [rel_1, rel_2] }

    describe "del" do
      it "deletes all the relationships" do
        rel_1.should_receive(:del)
        rel_2.should_receive(:del)
        subject.del
      end
    end

    context "when specifying a #to_other" do
      before do
        subject.to_other(rel_2.end_node)
      end

      its(:count) { should == 1 }
      its(:size) { should == 1 }
      its(:to_a) { should == [rel_2] }

      context "when specifying #outgoing instead of :both" do
        before do
          subject.outgoing
        end

        its(:count) { should == 1 }
        its(:size) { should == 1 }
        its(:to_a) { should == [rel_2] }
      end

      context "when specifying #incoming instead of :both" do
        before do
          subject.incoming
        end

        its(:count) { should == 0 }
        its(:size) { should == 0 }
        its(:to_a) { should == [] }
      end

    end
  end

  context "a node with no relationships" do
    subject { Neo4j::Core::Rels::Traverser.new(a_node, [:foo, :bar]) }

    before do
      java_array = Java::java.util.ArrayList.new
      subject.stub(:iterator) { java_array.iterator }
    end

    its(:count) { should == 0 }
    its(:size) { should == 0 }
    its(:to_a) { should == [] }
  end

  context "when initialized with two rel types" do
    subject { Neo4j::Core::Rels::Traverser.new(a_node, [:foo, :bar]) }

    it "can initialize it properly" do
      subject.node.should == a_node
      subject.dir.should == :both
      subject.types.should == [:foo, :bar]
    end

    its(:to_s) { should be_kind_of(String) }

    describe "iterator" do
      it "calls the Neo4j::Node.rels with 3 args" do
        a_node.should_receive(:_rels).with(:both, :foo, :bar).and_return('iterator')
        subject.iterator.should == 'iterator'
      end
    end

  end

  context "when initialized with one rel type" do
    subject { Neo4j::Core::Rels::Traverser.new(a_node, [:foo]) }

    it "can initialize it properly" do
      subject.node.should == a_node
      subject.dir.should == :both
      subject.types.should == [:foo]
    end

    its(:to_s) { should be_kind_of(String) }

    describe "iterator" do
      it "calls the Neo4j::Node.rels with 2 args" do
        a_node.should_receive(:_rels).with(:both, :foo).and_return('iterator')
        subject.iterator.should == 'iterator'
      end
    end

  end

  context "when initialized with zero rel types" do
    subject { Neo4j::Core::Rels::Traverser.new(a_node, []) }

    it "can initialize it properly" do
      subject.node.should == a_node
      subject.dir.should == :both
      subject.types.should == []
    end

    its(:to_s) { should be_kind_of(String) }

    describe "iterator" do
      it "calls the Neo4j::Node.rels with 0 args" do
        a_node.should_receive(:_rels).with(:both).and_return('iterator')
        subject.iterator.should == 'iterator'
      end
    end

  end
end