require 'spec_helper'

describe Neo4j::Server::Resource do

  class MyResource
    include Neo4j::Server::Resource
    def initialize(response, url)
      init_resource_data(response.body, url)
    end
  end

  describe '#resource_url' do
    it 'returns the base url for the result if no param given' do
      body = {'stuff' => '/data/bla/{hej}'}
      request = double('request', body: body, code: 200)
      resource = MyResource.new(request, 'url')
      expect(resource.resource_url).to eq('url')
    end

    it 'returns the hyperlink' do
      body = {'stuff' => '/data/bla/2'}
      request = double('request', body: body, code: 200)
      resource = MyResource.new(request, 'url')
      expect(resource.resource_url(:stuff)).to eq('/data/bla/2')
    end

  end

  describe '#resource_url_id' do
    let(:request) { Struct.new(:body, :code).new({}.to_json, 200) }
    it 'returns the last digits of the url' do
      expect(MyResource.new(request, 'http://foo/123').resource_url_id).to eq(123)
      expect(MyResource.new(request, 'http://123/42').resource_url_id).to eq(42)
    end
  end
end
