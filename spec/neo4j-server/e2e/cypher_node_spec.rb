require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do

  it 'can create' do
    node = Neo4j::Transaction.run do
      Neo4j::Node.create
    end
    puts "FIND #{node.neo_id}"
    expect(node).to exist
  end
  it_behaves_like "Neo4j::Node auto tx"
  it_behaves_like "Neo4j::Node with tx"

end
