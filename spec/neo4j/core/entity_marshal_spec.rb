require 'spec_helper'

describe 'Node and relationship marshaling' do
  describe 'nodes' do
    before { create_server_session }
    let(:node) { Neo4j::Session.current.query("CREATE (n:Test {foo: 'bar'}) RETURN n").to_a[0].n }

    it 'marshals correctly' do
      unmarshaled = Marshal.load(Marshal.dump(node))

      expect(unmarshaled).to be_a(Neo4j::Server::CypherNode)
      expect(unmarshaled.props[:foo]).to eq('bar')
      expect(unmarshaled.labels).to eq([:Test])
    end
  end

  describe 'relationships' do
    before { create_server_session }
    let(:rel) { Neo4j::Session.current.query("CREATE ()-[r:TEST {foo: 'bar'}]->() RETURN r").to_a[0].r }

    it 'marshals correctly' do
      unmarshaled = Marshal.load(Marshal.dump(rel))

      expect(unmarshaled).to be_a(Neo4j::Server::CypherRelationship)
      expect(unmarshaled.props[:foo]).to eq('bar')
      expect(unmarshaled.rel_type).to eq(:TEST)
    end
  end
end
