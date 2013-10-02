require 'spec_helper'

describe 'label' do

  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474")
  end

  after(:all) do
    @db.unregister
  end

  before(:each) do
    clean_server_db
  end

  it_behaves_like "Neo4j::Label"

end