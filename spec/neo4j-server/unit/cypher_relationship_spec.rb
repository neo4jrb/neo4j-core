require 'spec_helper'

describe Neo4j::Server::CypherRelationship, api: :server do
  describe '_start_node_id and _end_node_id' do
    let(:n1) { Neo4j::Node.create }
    let(:n2) { Neo4j::Node.create }
    it 'returns the ID of the node at the start and end of the rel' do
      a = n1.create_rel(:knows, n2, since: 1996)
      expect(a._start_node_id).to eq n1.neo_id
      expect(a._end_node_id).to eq n2.neo_id
    end
  end
end
