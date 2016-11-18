# Requires that an `http_adaptor` let variable exist with the Faraday adaptor name
RSpec.shared_examples 'Neo4j::Server::CypherSession' do
  it 'should be able to connect and query' do
    create_server_session(http_adaptor: http_adaptor).query.create('(n)').return('ID(n) AS id').first[:id]
  end
end
