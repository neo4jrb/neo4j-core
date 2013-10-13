require 'spec_helper'

describe Neo4j::Server::CypherRelationship, api: :server do

  it_behaves_like "Neo4j::Relationship"

end