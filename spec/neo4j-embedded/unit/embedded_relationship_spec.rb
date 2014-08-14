require 'spec_helper'

describe "Neo4j::Embedded::EmbeddedRelationship", api: :embedded do

  describe '_start_node_id and _end_node_id' do
    let(:n1) { Neo4j::Node.create }
    let(:n2) { Neo4j::Node.create }
    #server returns ids, embedded returns whole nodes because it can
    #the method relying on this will accept either
    it 'returns the nodes at the start and end of the rel' do
      a = n1.create_rel(:knows, n2, {since: 1996})
      expect(a._start_node_id).to eq n1
      expect(a._end_node_id).to eq n2
    end
  end
end
