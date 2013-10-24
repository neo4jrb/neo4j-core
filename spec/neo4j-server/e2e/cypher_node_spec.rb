require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do

  #it_behaves_like "Neo4j::Node auto tx"
  #it_behaves_like "Neo4j::Node with tx"

  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }
  let(:node_c) { Neo4j::Node.create(name: 'c') }
  let(:node_d) { Neo4j::Node.create(name: 'd') }

  describe 'rel?' do
    it "returns true relationship if there is only one" do
      node_a.create_rel(:knows, node_b)
      node_a.rel(type: :knows, dir: :outgoing).should be_true
      node_a.rel(type: :knows, dir: :incoming).should be_false
      node_a.rel(type: :knows).should be_true
    end

    it 'returns true if there is more then one matching relationship' do
      node_a.create_rel(:knows, node_b)
      node_a.create_rel(:knows, node_b)
      node_a.rel?(type: :knows).should be_true
      node_a.rel?(dir: :outgoing, type: :knows).should be_true
      node_a.rel?(dir: :both, type: :knows).should be_true
      node_a.rel?(dir: :incoming, type: :knows).should be_false
    end

  end

  describe 'rel' do
    it "returns the relationship if there is only one" do
      rel = node_a.create_rel(:knows, node_b)
      node_a.rel(type: :knows, dir: :outgoing).should == rel
      node_a.rel(type: :knows, dir: :incoming).should be_nil
      node_a.rel(type: :knows).should == rel
    end

    it 'raise an exception if there are more then one matching relationship' do
      node_a.create_rel(:knows, node_b)
      node_a.create_rel(:knows, node_b)

      expect{node_a.rel(:knows)}.to raise_error
    end
  end


  describe 'node' do
    describe 'node()' do
      it 'returns a node if there is any outgoing,incoming relationship of any type to it' do
        node_a.create_rel(:work, node_b)
        node_a.node().should == node_b
      end

      it 'returns nil if there is no relationships' do
        node_a.node().should be_nil
      end

      it 'raise an exception if there are more then one relationship' do
        node_a.create_rel(:work, node_b)
        node_a.create_rel(:work, node_b)
        expect{ node_a.node().should == node_b}.to raise_error
      end
    end

    describe 'node(dir: :outgoing, type: :friends)' do
      it 'returns a node if there is any outgoing,incoming relationship of any type to it' do
        node_a.create_rel(:friends, node_b)
        node_a.node(dir: :outgoing, type: :friends).should == node_b
        node_a.node(dir: :incoming, type: :friends).should be_nil
        node_a.node(dir: :outgoing, type: :knows).should be_nil
      end

    end

  end


end