require 'spec_helper'

describe 'label' do

  before(:all) do
    @session = Neo4j::Session.current || Neo4j::Session.open(:server_db, "http://localhost:7474")
  end

  after(:all) do
    @session && @session.close
  end

  before(:all) do
    clean_server_db
  end

  it_behaves_like "Neo4j::Label"

end