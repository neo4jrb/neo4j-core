require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do

  it 'handles nested transaction' do
    skip "need to simulate Placebo Transaction as done in Embedded Db"
    Neo4j::Transaction.run do
      Neo4j::Transaction.run do
        Neo4j::Node.create
      end
    end
  end
  it_behaves_like "Neo4j::Node auto tx"
  it_behaves_like "Neo4j::Node with tx"

end

