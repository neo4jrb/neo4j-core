require 'spec_helper'

module Neo4j::Server


  describe CypherSession, api: :server do

    def open_session
      create_server_session
    end

    def open_named_session(name, default = nil)
      create_named_server_session(name, default)
    end

    it_behaves_like "Neo4j::Session"

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
        session.query.create("(n)").return("ID(n) AS id").first[:id]
      end

      it 'returns a result containing data,columns and error?' do
        result = session._query("START n=node(#{a_node_id}) RETURN ID(n)")
        expect(result.data).to eq([[a_node_id]])
        expect(result.columns).to eq(['ID(n)'])
        expect(result.error?).to be false
      end

      it "allows you to specify parameters" do
        result = session._query("START n=node({myparam}) RETURN ID(n)", myparam: a_node_id)
        expect(result.data).to eq([[a_node_id]])
        expect(result.columns).to eq(['ID(n)'])
        expect(result.error?).to be false
      end

      it 'returns error codes if not a valid cypher query' do
        result = session._query("SSTART n=node(0) RETURN ID(n)")
        expect(result.error?).to be true
        expect(result.error_msg).to match(/Invalid input/)
        expect(result.error_status).to eq('SyntaxException')
        expect(result.error_code).not_to be_empty
      end
    end

  end

end
