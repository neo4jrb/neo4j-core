require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/http'

describe Neo4j::Core::CypherSession::Adaptors::HTTP do
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::HTTP }

  describe '#initialize' do
    it 'validates URLs' do
      expect { adaptor_class.new('url') }.to raise_error ArgumentError, /Invalid URL:/
      expect { adaptor_class.new('https://foo@localhost:7474') }.to raise_error ArgumentError, /Invalid URL:/

      expect { adaptor_class.new('http://localhost:7474') }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474') }.not_to raise_error
      expect { adaptor_class.new('https://localhost:7474/') }.not_to raise_error
      expect { adaptor_class.new('https://foo:bar@localhost:7474') }.not_to raise_error
    end
  end

  describe '#query' do
    let(:adaptor) { adaptor_class.new(ENV['NEO4J_URL']) }

    it 'Can make a query' do
      adaptor.connect

      adaptor.query('MERGE path=n-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end
  end
end