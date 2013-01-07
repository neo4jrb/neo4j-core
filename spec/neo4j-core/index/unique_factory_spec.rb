require 'spec_helper'

describe Neo4j::Core::Index::UniqueFactory do
  let(:index) { mock('Index')}
  let(:tx) { mock("transaction")}

  before do
    Neo4j::Transaction.stub(:new).and_return(tx)
  end

  let(:created_node) do
    created_node = mock("Node")
    created_node.stub(:_java_entity) { created_node}
    created_node
  end


  describe "using a custom factory block" do
    subject do
      Neo4j::Core::Index::UniqueFactory.new(:email, index) do |k,v|
        n = "NewThing #{k}=#{v}"
        n.stub(:_java_entity){n}
        n
      end
    end

    context "when it does not exist" do
      it "creates and returns a new node" do
        result = "NewThing email=foo@gmail.com"
        index.should_receive(:get).with("email", "foo@gmail.com").and_return(Struct.new(:get_single).new)
        index.should_receive(:put_if_absent).with(result, "email", "foo@gmail.com").and_return(nil)
        tx.should_receive(:success)
        tx.should_receive(:finish)
        subject.get_or_create(:email, "foo@gmail.com").should == result
      end
    end
  end

  describe "create a default node factory" do

    subject do
      Neo4j::Core::Index::UniqueFactory.new(:email, index)
    end


    context "when it does not exist" do
      it "creates and returns a new node" do
        Neo4j::Node.should_receive(:new).with("email" => "foo@gmail.com").and_return(created_node)
        index.should_receive(:get).with("email", "foo@gmail.com").and_return(Struct.new(:get_single).new)
        index.should_receive(:put_if_absent).with(created_node, "email", "foo@gmail.com").and_return(nil)
        tx.should_receive(:success)
        tx.should_receive(:finish)
        subject.get_or_create(:email, "foo@gmail.com").should == created_node
      end
    end

    context "when put_if_absent finds an existing node" do
      it "returns the existing node" do
        Neo4j::Node.should_receive(:new).with("email" => "foo@gmail.com").and_return(created_node)
        index.should_receive(:get).with("email", "foo@gmail.com").and_return(Struct.new(:get_single).new)
        existing_node = mock("an existing node")
        index.should_receive(:put_if_absent).with(created_node, "email", "foo@gmail.com").and_return(existing_node)
        created_node.should_receive(:del)
        tx.should_receive(:success)
        tx.should_receive(:finish)
        subject.get_or_create(:email, "foo@gmail.com").should == existing_node
      end
    end

    context "when it finds an existing node" do
      it "returns the existing node" do
        existing_node = mock("an existing node")
        index.should_receive(:get).with("email", "foo@gmail.com").and_return(Struct.new(:get_single).new(existing_node))
        tx.should_receive(:finish)
        subject.get_or_create(:email, "foo@gmail.com").should == existing_node
      end
    end

  end
end