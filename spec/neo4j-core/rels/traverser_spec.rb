require 'spec_helper'

describe Neo4j::Core::Rels::Traverser do

  before do
    Neo4j::Core::ToJava.stub(:type_to_java) { |x| x }
    Neo4j::Core::ToJava.stub(:dir_to_java) { |x| x }
  end

  describe "initialize" do
    let(:a_node) { MockNode.new }

    it "can initialize it with two rel types" do
      trav = Neo4j::Core::Rels::Traverser.new(a_node, [:foo, :bar])
      trav.node.should == a_node
      trav.dir.should == :both
      trav.types.java_class.to_s.should == "[Lorg.neo4j.graphdb.RelationshipType;"
    end

    it "can initialize it with one rel types" do
      trav = Neo4j::Core::Rels::Traverser.new(a_node, [:foo])
      trav.node.should == a_node
      trav.dir.should == :both
      trav.type.java_class.to_s.should == "org.neo4j.graphdb.DynamicRelationshipType"
    end

  end
end