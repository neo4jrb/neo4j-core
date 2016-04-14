require 'spec_helper'

module Neo4j
  module Server
    describe CypherSession, api: :server do
      def open_session
        create_server_session
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
          connection = Faraday.new do |faraday|
            faraday.request :basic_auth, basic_auth_hash[:username], basic_auth_hash[:password]

            faraday.request :multi_json
            faraday.response :multi_json, symbolize_keys: true, content_type: 'application/json'
            faraday.adapter Faraday.default_adapter
          end
          connection.headers = {'Content-Type' => 'application/json'}

          expect(connection).to receive(:get).at_least(:once).and_call_original
          create_server_session(connection: connection)
        end

        it 'adds host and port to the connection object' do
          connection = Neo4j::Session.current.connection
          expect(connection.port).to eq ENV['NEO4J_URL'] ? URI(ENV['NEO4J_URL']).port : 7474
          expect(connection.host).to eq 'localhost'
        end
      end


      describe 'named sessions' do
        before { Neo4j::Session.current && Neo4j::Session.current.close }
        after { Neo4j::Session.current && Neo4j::Session.current.close }

        it 'stores a named session' do
          name = :test
          test = Neo4j::Session.open(:server_db, server_url, name: name)
          expect(Neo4j::Session.named(name)).to eq(test)
        end

        it 'does not override the current session when default = false' do
          default = open_session
          expect(Neo4j::Session.current).to eq(default)
          name = :test
          Neo4j::Session.open(:server_db, server_url, name: name)
          expect(Neo4j::Session.current).to eq(default)
        end

        it 'makes the new session current when default = true' do
          default = open_session
          expect(Neo4j::Session.current).to eq(default)
          name = :test
          test = Neo4j::Session.open(:server_db, server_url, name: name, default: true)
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

    describe '_query_or_fail' do
      context 'with a retryable error' do
        let(:session) { Neo4j::Session.current }
        let(:match_string) { 'MATCH (n) RETURN COUNT(n)' }
        let(:transient_error) { double('A response object with a transient error', error?: true, retryable_error?: true) }

        context 'with retry count > 0' do
          it 'retries and decreases limit' do
            expect(session).to receive(:_query).and_return(transient_error)
            expect(session).to receive(:_query_or_fail).with(match_string, true, nil, 2).and_call_original
            expect(session).to receive(:_query_or_fail).with(match_string, true, nil, 1)
            session._query_or_fail(match_string, true, nil, 2)
          end

          context 'success' do
            let(:successful_response) { double('A response object with no errors') }
            it 'does not process the response twice' do
              expect(session).to receive(:_query).and_return(transient_error)
              expect(session).to receive(:_query_or_fail).with(match_string, true, nil, 2).and_call_original
              expect(session).to receive(:_retry_or_raise).and_return(successful_response)
              expect(successful_response).not_to receive(:first_data)
              session._query_or_fail(match_string, true, nil, 2)
            end
          end
        end

        context 'with retry count exhausted' do
          it 'raises an error' do
            expect(session).to receive(:_query).and_return(transient_error)
            expect(transient_error).to receive(:raise_error)
            session._query_or_fail(match_string, true, nil, 0)
          end
        end
      end
    end
  end
end
