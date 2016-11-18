require 'spec_helper'
require 'neo4j/core/cypher_session/adapters/embedded'
require './spec/neo4j/core/shared_examples/adapter'
require 'tmpdir'

describe Neo4j::Core::CypherSession::Adapters::Embedded do
  let(:adapter_class) { Neo4j::Core::CypherSession::Adapters::Embedded }

  if Neo4j::Core::Config.using_new_session?
    if RUBY_PLATFORM == 'java'
      describe '#initialize' do
        it 'validates path' do
          expect { adapter_class.new('./spec/fixtures/notadirectory') }.to raise_error ArgumentError, /Invalid path:/
          expect { adapter_class.new('./spec/fixtures/adirectory') }.not_to raise_error
        end
      end

      before(:all) do
        path = Dir.mktmpdir('neo4jrb_embedded_adapter_spec')
        @adapter = Neo4j::Core::CypherSession::Adapters::Embedded.new(path)
        @adapter.connect
      end

      let(:adapter) { @adapter }

      it_behaves_like 'Neo4j::Core::CypherSession::Adapter'
    else
      it 'should raise an error' do
        expect { adapter_class.new('/') }.to raise_error 'JRuby is required for embedded mode'
      end
    end
  end
end
