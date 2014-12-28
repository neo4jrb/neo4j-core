require 'spec_helper'

module Neo4j::Server
  describe CypherSession, api: :server do

    def open_session
      create_server_session
    end

    def open_named_session(name, default = nil)
      create_named_server_session(name, default)
    end

    it_behaves_like 'Neo4j::Session'

    describe '.open' do
      before(:all) do
        @before_session = Neo4j::Session.current
      end

      after(:all) do
        Neo4j::Session.set_current(@before_session)
      end

      it 'can use a user supplied faraday connection for a new session' do
        connection = Faraday.new do |b|
          b.request :json
          b.response :json, content_type: 'application/json'
          b.adapter Faraday.default_adapter
        end
        connection.headers = {'Content-Type' => 'application/json'}

        expect(connection).to receive(:get).at_least(:once).and_call_original
        session = Neo4j::Session.open(:server_db, 'http://localhost:7474',  connection: connection)
      end
    end


    describe 'named sessions' do

      before { Neo4j::Session.current && Neo4j::Session.current.close }
      after { Neo4j::Session.current && Neo4j::Session.current.close }

      it 'stores a named session' do
        name = :test
        test = open_named_session(name)
        expect(Neo4j::Session.named(name)).to eq(test)
      end

      it 'does not override the current session when default = false' do
        default = open_session
        expect(Neo4j::Session.current).to eq(default)
        name = :tesr
        open_named_session(name)
        expect(Neo4j::Session.current).to eq(default)
      end

      it 'makes the new session current when default = true' do
        default = open_session
        expect(Neo4j::Session.current).to eq(default)
        name = :test
        test = open_named_session(name, true)
        expect(Neo4j::Session.current).to eq(test)
      end
    end

    describe '_query' do
      let(:a_node_id) do
        session.query.create('(n)').return('ID(n) AS id').first[:id]
      end

      it 'returns a result containing data,columns and error?' do
        result = session._query("MATCH (n) WHERE ID(n) = #{a_node_id} RETURN ID(n)")
        expect(result.data).to eq([[a_node_id]])
        expect(result.columns).to eq(['ID(n)'])
        expect(result.error?).to be false
      end

      it 'allows you to specify parameters' do
        result = session._query('MATCH (n) WHERE ID(n) = {id_param} RETURN ID(n)', id_param: a_node_id)
        expect(result.data).to eq([[a_node_id]])
        expect(result.columns).to eq(['ID(n)'])
        expect(result.error?).to be false
      end

      it 'returns error codes if not a valid cypher query' do
        result = session._query('SSTART n=node(0) RETURN ID(n)')
        expect(result.error?).to be true
        expect(result.error_msg).to match(/Invalid input/)
        expect(result.error_status).to eq('SyntaxException')
        expect(result.error_code).not_to be_empty
      end
    end

    subject { Neo4j::Session.current.to_s }
    it { is_expected.to include 'Neo4j::Server::CypherSession url:' }

    subject { Neo4j::Session.current.inspect }
    it { is_expected.to include 'Neo4j::Server::CypherSession url:' }
  end
end
