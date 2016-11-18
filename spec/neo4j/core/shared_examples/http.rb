# Requires that an `http_adaptor` let variable exist with the Faraday adaptor name
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adaptors::Http' do
  it "should connect properly" do
    subject.class.new(url, http_adaptor: http_adaptor).connect.get('/')
  end
end