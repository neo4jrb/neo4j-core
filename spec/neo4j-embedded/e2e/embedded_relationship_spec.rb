require 'spec_helper'

describe "Neo4j::Embedded::EmbeddedRelationship", api: :embedded do

  it_behaves_like "Neo4j::Relationship"

end