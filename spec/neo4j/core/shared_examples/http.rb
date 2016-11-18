# Requires that an `http_adaptor` let variable exist with the Faraday adaptor name
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adaptors::Http' do
  it "should connect properly" do
    Neo4j::Core::CypherSession::Adaptors::HTTP.new(url, http_adapter: http_adaptor).connect.get('/')
  end
end