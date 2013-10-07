require 'spec_helper'

describe Neo4j::Server::CypherNode do

  before(:all) do
    @session = Neo4j::Server::CypherDatabase.connect("http://localhost:7474")
  end

  after(:all) do
    @session.close
  end

  before(:all) do
    clean_server_db
  end

  it_behaves_like "Neo4j::Node auto tx"
  it_behaves_like "Neo4j::Node with tx"

end