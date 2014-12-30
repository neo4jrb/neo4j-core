require 'spec_helper'
require 'httparty'

def url_for(rel_url)
  'http://localhost:7474/db/data'
end

tx_url = 'http://localhost:7474/db/data/transaction'
resource_headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}

describe 'Transaction', api: :server do
  describe 'create' do
    after do
      # close
      if @commit_url
        HTTParty.send(:post, @commit_url, headers: resource_headers)
      end
    end


    it 'create tx' do
      response = HTTParty.send(:post, tx_url, headers: resource_headers)

      @commit_url = response['commit']
      @exec_url = response.headers['location']


      # create an node

      # Neo4j::Transaction.run do
      #   node = Neo4j::Node.create({name: 'Andres', title: 'Developer'}, :Person)
      body = {statements: [{statement: "CREATE (n:Person { name : 'Andres', title : 'Developer', _key : 'SHA' }) RETURN id(n)"}]}.to_json

      response = HTTParty.send(:post, @exec_url, headers: resource_headers, body: body)
      expect(response.code).to eq(200)

      #   node.name = 'foo'
      body = {statements: [{statement: 'MATCH (movie:Person) RETURN movie'}]}.to_json

      response = HTTParty.send(:post, @exec_url, headers: resource_headers, body: body)
      expect(response.code).to eq(200)
    end
  end
end
