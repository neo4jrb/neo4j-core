require 'spec_helper'

describe Neo4j::Server::CypherRelationship do

  before(:all) do
    @session = Neo4j::Session.current || Neo4j::Session.open(:server_db, "http://localhost:7474")
  end

  after(:all) do
    @session && @session.close
  end

  it_behaves_like "Neo4j::Relationship"

end