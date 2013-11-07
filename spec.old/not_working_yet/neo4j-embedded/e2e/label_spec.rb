require 'spec_helper'

describe 'label' do

  before(:all) do
    # TODO use ImpermanentDatabase
    @db = Neo4j::Embedded::Database.new('path', delete_existing_db: true, auto_commit: true)
    clean_embedded_db
  end

  after(:all) do
    @db.shutdown
  end

  it_behaves_like "Neo4j::Label"

end