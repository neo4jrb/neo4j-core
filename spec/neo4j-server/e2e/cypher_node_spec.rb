require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :server do

  it_behaves_like "Neo4j::Node auto tx"
  it_behaves_like "Neo4j::Node with tx"

end
