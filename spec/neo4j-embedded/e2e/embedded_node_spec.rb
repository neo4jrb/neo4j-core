require 'spec_helper'

describe Neo4j::Server::CypherNode, api: :embedded do


  #it_behaves_like "Neo4j::Node auto tx"


  #it_behaves_like "Neo4j::Node with tx"

  it "works" do
    Neo4j::Node.create(name: 'a')
  end

end