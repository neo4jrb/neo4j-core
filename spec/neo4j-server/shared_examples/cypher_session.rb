# Requires that an `http_adaptor` let variable exist with the Faraday adaptor name
RSpec.shared_examples 'Neo4j::Server::CypherSession' do
  it 'should be able to connect and query' do
    create_server_session(faraday_options: {adapter: adapter}).query.create('(n)').return('ID(n) AS id').first[:id]
  end
end
