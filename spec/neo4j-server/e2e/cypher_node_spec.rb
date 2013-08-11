require 'spec_helper'

describe Neo4j::Server::CypherNode do

  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474")
  end

  after(:all) do
    @db.unregister
  end

  it_behaves_like "Neo4j::Node"

end