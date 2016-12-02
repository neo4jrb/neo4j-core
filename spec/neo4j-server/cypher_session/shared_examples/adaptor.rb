RSpec.shared_examples 'Neo4j::Server::CypherSession::Adaptor' do
  describe 'faraday_options' do
    describe 'a faraday connection type adapter option' do
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

      it 'will pass through a symbol key' do
        expect_any_instance_of(Faraday::Connection).to receive(:adapter).with(:typhoeus).and_call_original
        create_server_session(faraday_options: {adapter: :typhoeus})
      end

      it 'will pass through a string key' do
        expect_any_instance_of(Faraday::Connection).to receive(:adapter).with(:typhoeus).and_call_original
        create_server_session('faraday_options' => {'adapter' => :typhoeus})
      end
    end
  end
end
