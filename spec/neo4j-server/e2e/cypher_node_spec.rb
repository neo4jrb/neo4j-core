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
      Neo4j::Node.create()
    end
  end

end