require 'spec_helper'



describe "Embedded Neo4j::Node" do
  before(:all) do
    @db = Neo4j::Embedded::Database.new('path', delete_existing_db: true, auto_commit: true)
  end

  after(:all) do
    @db.shutdown
  end

  it_behaves_like "Neo4j::Node"

end

describe "Server Neo4j::Node" do
  before(:all) do
    @db = Neo4j::Server::Database.new('path', delete_existing_db: true, auto_commit: true)
  end

  after(:all) do
    @db.shutdown
  end

  it_behaves_like "Neo4j::Node"

end