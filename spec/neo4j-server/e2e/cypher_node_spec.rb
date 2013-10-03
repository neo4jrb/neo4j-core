require 'spec_helper'

describe Neo4j::Server::CypherNode do

  before(:all) do
    @session = Neo4j::Server::CypherDatabase.connect("http://localhost:7474")
  end

  after(:all) do
    @session.close
  end

  it_behaves_like "Neo4j::Node"

  describe 'label' do
    it 'can create a node with a label' do
      node = Neo4j::Node.create({}, :my_label, :label2)
      node.labels.to_a.should include(:my_label, :label2)
      node.labels.count.should == 2
    end
  end

end