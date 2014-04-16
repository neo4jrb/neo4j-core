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
        @endpoint = Neo4jServerEndpoint.new(nil, nil)
      end

      it "should allow HTTP requests WITHOUT params" do
        HTTParty.should_receive(:get).with(url).and_return(response)
        expect(@endpoint.get(url)).to eq(response)

        HTTParty.should_receive(:post).with(url).and_return(response)
        expect(@endpoint.post(url)).to eq(response)

        HTTParty.should_receive(:delete).with(url).and_return(response)
        expect(@endpoint.delete(url)).to eq(response)
      end

      it "should allow HTTP requests WITH params" do
        params = { key1: 1, key2: 2 }

        HTTParty.should_receive(:get).with(url, params).and_return(response)
        expect(@endpoint.get(url, params)).to eq(response)

        HTTParty.should_receive(:post).with(url, params).and_return(response)
        expect(@endpoint.post(url, params)).to eq(response)

        HTTParty.should_receive(:delete).with(url, params).and_return(response)
        expect(@endpoint.delete(url, params)).to eq(response)
      end
    end

    describe "for requests with basic auth" do
      before(:each) do
        @basic_auth = { basic_auth: { username: "U", password: "P"} }
        @endpoint = Neo4jServerEndpoint.new(nil, @basic_auth)
      end
      
      it "should allow HTTP requests WITHOUT other params" do
        HTTParty.should_receive(:get).with(url, @basic_auth).and_return(response)
        expect(@endpoint.get(url)).to eq(response)

        HTTParty.should_receive(:post).with(url, @basic_auth).and_return(response)
        expect(@endpoint.post(url)).to eq(response)

        HTTParty.should_receive(:delete).with(url, @basic_auth).and_return(response)
        expect(@endpoint.delete(url)).to eq(response)
      end

      it "should allow HTTP requests WITH other params" do
        params = { key1: 1, key2: 2 }
        merged_params = params.merge(@basic_auth)

        HTTParty.should_receive(:get).with(url, merged_params).and_return(response)
        expect(@endpoint.get(url, params)).to eq(response)

        HTTParty.should_receive(:post).with(url, merged_params).and_return(response)
        expect(@endpoint.post(url, params)).to eq(response)

        HTTParty.should_receive(:delete).with(url, merged_params).and_return(response)
        expect(@endpoint.delete(url, params)).to eq(response)
      end
    end
  end
end