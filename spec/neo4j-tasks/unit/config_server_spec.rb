require 'spec_helper'

require 'neo4j/tasks/config_server'

describe Neo4j::Tasks::ConfigServer do

  describe '.set_property' do
    let(:data) do
      <<-HERE
  # Turn https-support on/off
org.neo4j.server.webserver.https.else=true
org.neo4j.server.webserver.https.enabled=true
      HERE
    end

    it 'can set properties' do
      expect(Neo4j::Tasks::ConfigServer.set_property(data, 'org.neo4j.server.webserver.https.enabled', 'false')).to match(/org.neo4j.server.webserver.https.enabled=false/)
    end

    it 'does not set other properties' do
      expect(Neo4j::Tasks::ConfigServer.set_property(data, 'org.neo4j.server.webserver.https.enabled', 'false')).to match(/org.neo4j.server.webserver.https.else=true/)
    end
  end

  describe '.config' do
    let(:data) do
      <<-HERE
  # Turn https-support on/off
org.neo4j.server.webserver.https.else=true
org.neo4j.server.webserver.port=7474
org.neo4j.server.webserver.https.enabled=true
      HERE
    end

    it 'sets the server port' do
      # org.neo4j.server.webserver.port=7474
      expect(Neo4j::Tasks::ConfigServer.config(data, 8888)).to match(/org.neo4j.server.webserver.port=8888/)
    end
  end
end