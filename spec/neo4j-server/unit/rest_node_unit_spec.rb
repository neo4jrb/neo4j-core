require 'spec_helper'

describe Neo4j::Server::RestNode do
  let(:dummy_request) { double("dummy request", path: 'http://dummy.request')}

  let(:node_response_body) do
    <<-HERE
    {
    "extensions" : {
    },
    "outgoing_relationships" : "http://localhost:7474/db/data/node/394/relationships/out",
    "labels" : "http://localhost:7474/db/data/node/394/labels",
    "all_typed_relationships" : "http://localhost:7474/db/data/node/394/relationships/all/{-list|&|types}",
    "traverse" : "http://localhost:7474/db/data/node/394/traverse/{returnType}",
    "self" : "http://localhost:7474/db/data/node/394",
    "property" : "http://localhost:7474/db/data/node/394/properties/{key}",
    "outgoing_typed_relationships" : "http://localhost:7474/db/data/node/394/relationships/out/{-list|&|types}",
    "properties" : "http://localhost:7474/db/data/node/394/properties",
    "incoming_relationships" : "http://localhost:7474/db/data/node/394/relationships/in",
    "create_relationship" : "http://localhost:7474/db/data/node/394/relationships",
    "paged_traverse" : "http://localhost:7474/db/data/node/394/paged/traverse/{returnType}{?pageSize,leaseTime}",
    "all_relationships" : "http://localhost:7474/db/data/node/394/relationships/all",
    "incoming_typed_relationships" : "http://localhost:7474/db/data/node/394/relationships/in/{-list|&|types}",
    "data" : {
      "name" : "Steven"
    }
  }
    HERE
  end

  let(:db) { double("rest database")}


  describe 'instance methods' do
    let(:node) do
      response = double('response', body: node_response_body)
      Neo4j::Server::RestNode.new(db, response, 'http://localhost:7474/db/data/node/394')
    end

    describe 'initialize' do
      it "initialize the resource" do
        node.neo_id.should == 394
        node.resource_url(:labels).should == 'http://localhost:7474/db/data/node/394/labels'
      end
    end

    describe 'add_label' do
      it "does a POST on the labels resource" do
        HTTParty.should_receive(:post)
          .with('http://localhost:7474/db/data/node/394/labels', {body: ['person'].to_json})
          .and_return(double('response', code: 201, request: dummy_request))
        node.add_label(:person)
      end
    end
  end
end