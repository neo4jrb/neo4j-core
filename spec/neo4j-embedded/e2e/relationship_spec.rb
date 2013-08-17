require 'spec_helper'

describe "Embedded Neo4j::Relationship" do

  before(:all) do
    @db = Neo4j::Embedded::Database.new('path', delete_existing_db: true, auto_commit: true)
  end

  after(:all) do
    @db.unregister
  end

  it_behaves_like "Neo4j::Relationship"

end