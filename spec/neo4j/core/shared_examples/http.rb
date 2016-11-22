# Requires that an `http_adaptor` let variable exist with the Faraday adaptor name
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adaptors::HTTP' do
  it 'should connect properly' do
    Neo4j::Core::CypherSession::Adaptors::HTTP.new(server_url, faraday_options: {adapter: adapter}).connect.get('/')
  end
end
