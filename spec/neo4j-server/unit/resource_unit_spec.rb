require 'spec_helper'

describe Neo4j::Server::Resource do

  class MyResource
    include Neo4j::Server::Resource
    def initialize(response,url)
      init_resource_data(response.body,url)
    end
  end

  describe "resource_url" do
    it "replace {} args" do
      body = {'stuff' => '/data/bla/{hej}'}
      request = double("request", body: body, code: 200)
      resource = MyResource.new(request, 'url')
      resource.resource_url(:stuff, hej: 42).should == "/data/bla/42"
    end
  end

  describe "resource_url_id" do
    let(:request) { Struct.new(:body, :code).new({}.to_json, 200)}
    it "returns the last digits of the url" do
      MyResource.new(request, 'http://foo/123').resource_url_id.should == 123
      MyResource.new(request, 'http://123/42').resource_url_id.should == 42
    end
  end
end
