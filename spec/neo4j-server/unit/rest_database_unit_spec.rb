require 'spec_helper'

describe Neo4j::Server::RestDatabase do
  describe 'instance methods' do
    describe 'connect_to_server' do
      it 'initialize the resource if a 200 response' do
        body1 = <<-HERE
        {
          "management" : "http://localhost:7474/db/manage/",
          "data" : "http://localhost:7474/db/data/"
        }
        HERE
        response1 = Struct.new(:body, :code).new(body1, 200)

        body2 = <<-HERE
        {
        "extensions" : {
        },
        "node" : "http://localhost:7474/db/data/node",
        "reference_node" : "http://localhost:7474/db/data/node/0",
        "node_index" : "http://localhost:7474/db/data/index/node",
        "relationship_index" : "http://localhost:7474/db/data/index/relationship",
        "extensions_info" : "http://localhost:7474/db/data/ext",
        "relationship_types" : "http://localhost:7474/db/data/relationship/types",
        "batch" : "http://localhost:7474/db/data/batch",
        "cypher" : "http://localhost:7474/db/data/cypher",
        "transaction" : "http://localhost:7474/db/data/transaction",
        "neo4j_version" : "2.0.0-M03"
        }
        HERE

        response2 = Struct.new(:body, :code).new(body2, 200)
        HTTParty.should_receive(:get).with('http://url').and_return(response1)
        HTTParty.should_receive(:get).with('http://localhost:7474/db/data/').and_return(response2)
        Neo4j::Server::RestDatabase.new('http://url')
      end
    end

    describe '_query' do
      it '' do
        Neo4j::Server::RestDatabase
      end
    end
  end
end