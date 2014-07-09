require 'spec_helper'

def url_for(rel_url)
  "http://localhost:7474/db/data"
end

cypher_url = "http://localhost:7474/db/data/cypher"
resource_headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}

describe "Cypher Queries", api: :server do

  describe "CREATE (v1) RETURN ID(v1)" do
    it "returns correct response" do
      body = {query: 'CREATE (v1) RETURN ID(v1)'}.to_json
      response = HTTParty.send(:post, cypher_url, headers: resource_headers, body: body)
      response['columns'].should == ['ID(v1)']
      id = response['data'].first.first
      id.should be_a(Fixnum)
    end
  end

end