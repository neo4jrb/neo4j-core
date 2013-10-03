require 'spec_helper'

describe Neo4j::Server::CypherRelationship do

  before(:all) do
    @session = Neo4j::Server::CypherDatabase.connect("http://localhost:7474")
  end

  after(:all) do
    @session.close
  end

  it_behaves_like "Neo4j::Relationship"

end