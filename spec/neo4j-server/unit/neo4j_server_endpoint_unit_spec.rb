require 'spec_helper'

module Neo4j::Server
  describe Neo4jServerEndpoint do
    let(:response) do
      "RESPONSE"
    end

    let(:url) do
      "URL"
    end

    describe "for requests WITHOUT basic auth" do
      before(:each) do
        @endpoint = Neo4jServerEndpoint.new()
        @faraday = @endpoint.conn
      end

      it "should allow HTTP requests WITHOUT params" do
        expect(@faraday).to receive(:get).with(url, {}).and_return(response)
        expect(@endpoint.get(url).response).to eq(response)

        expect(@faraday).to receive(:post).and_return(response)
        expect(@endpoint.post(url).response).to eq(response)

        expect(@faraday).to receive(:delete).with(url, {}).and_return(response)
        expect(@endpoint.delete(url, {}).response).to eq(response)
      end

      it "should allow HTTP requests WITH params" do
        params = { key1: 1, key2: 2 }

        expect(@faraday).to receive(:get).with(url, params).and_return(response)
        expect(@endpoint.get(url, params).response).to eq(response)

        expect(@faraday).to receive(:post).with(url, params).and_return(response)
        expect(@endpoint.post(url, params).response).to eq(response)

        expect(@faraday).to receive(:delete).with(url, params).and_return(response)
        expect(@endpoint.delete(url, params).response).to eq(response)
      end
    end

    describe "for requests with basic auth" do
      before(:each) do
        @basic_auth = { basic_auth: { username: "U", password: "P"} }
        @endpoint = Neo4jServerEndpoint.new(@basic_auth)
        @faraday = @endpoint.conn
      end

      it "should configure a Faraday::RackBuilder::Handler" do
        handlers = @faraday.builder.handlers.map(&:name)
        expect(handlers).to include('Faraday::Request::BasicAuthentication')
      end
    end
  end
end