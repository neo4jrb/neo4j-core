require 'spec_helper'
require 'neo4j/tasks/config_server'

describe Neo4j::Tasks::ConfigServer do
  let(:mod) { Neo4j::Tasks::ConfigServer }

  describe '.set_property' do
    let(:data) do
      <<-HERE
  # Turn https-support on/off
org.neo4j.server.webserver.https.else=true
org.neo4j.server.webserver.https.enabled=true
      HERE
    end

    it 'can set properties' do
      expect(mod.set_property(data, 'org.neo4j.server.webserver.https.enabled', 'false')).to match(/org.neo4j.server.webserver.https.enabled=false/)
    end

    it 'does not set other properties' do
      expect(mod.set_property(data, 'org.neo4j.server.webserver.https.enabled', 'false')).to match(/org.neo4j.server.webserver.https.else=true/)
    end
  end

  describe '.config' do
    let(:data) do
      <<-HERE
  # Turn https-support on/off
org.neo4j.server.webserver.https.else=true
org.neo4j.server.webserver.port=7474
org.neo4j.server.webserver.https.enabled=true
org.neo4j.server.webserver.https.port=7473
      HERE
    end

    it 'sets the server port' do
      # org.neo4j.server.webserver.port=7474
      expect(mod.config(data, 8888)).to match('org.neo4j.server.webserver.port=8888')
      expect(mod.config(data, 8888)).to match('org.neo4j.server.webserver.https.port=8887')
    end
  end

  describe '.toggle_auth' do
    let(:data) do
      <<-HERE
  # Turn https-support on/off
dbms.security.authorization_enabled=false
      HERE
    end

    it 'changes changes authentication setting' do
      expect(mod.toggle_auth(:enable, data)).to match(/dbms.security.authorization_enabled=true/)
      expect(mod.toggle_auth(:disable, data)).to match(/dbms.security.authorization_enabled=false/)
    end
  end

  describe '.change_password' do
    let(:net) { Net::HTTP }
    let(:response) { double 'A response object from post_form' }
    let(:body) { {result: 'status'}.to_json }

    it 'POSTs to a given endpoint with a hash containing old/new passwords' do
      expect(net).to receive(:post_form).and_return response
      expect(response).to receive(:body).and_return body
      expect(mod.change_password('http://foo.bar:7474', 'foo', 'bar')).to eq JSON.parse(body)
    end
  end
end
