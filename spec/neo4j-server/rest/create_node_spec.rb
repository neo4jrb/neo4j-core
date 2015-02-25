require 'spec_helper'

def url_for(rel_url)
  'http://localhost:7474/db/data'
end

cypher_url = 'http://localhost:7474/db/data/cypher'

describe 'Cypher Queries', api: :server do
  describe 'CREATE (v1) RETURN ID(v1)' do
    it 'returns correct response' do
      body = {query: 'CREATE (v1) RETURN ID(v1)'}.to_json
      response_body = Faraday.new.post do |p|
        p.url cypher_url
        p.headers['Content-Type'] = 'application/json'
        p.headers['Accept'] = 'application/json'
        p.body = body
      end.body
      response = JSON.parse(response_body)
      expect(response['columns']).to eq(['ID(v1)'])
      id = response['data'].first.first
      expect(id).to be_a(Fixnum)
    end
  end
end
