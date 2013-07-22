require 'spec_helper'

describe Neo4j::Server::RestNode do

  before(:all) do
    @db = Neo4j::Server::RestDatabase.new("http://localhost:7474/db/data")
  end

  after(:all) do
    @db.unregister
  end

  it_behaves_like "Neo4j::Node"

end