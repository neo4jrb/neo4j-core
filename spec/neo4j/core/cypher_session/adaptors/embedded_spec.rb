require 'spec_helper'
require 'neo4j/core/cypher_session/adaptors/embedded'
require './spec/neo4j/core/shared_examples/adaptor'
require 'tmpdir'

describe Neo4j::Core::CypherSession::Adaptors::Embedded do
  let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::Embedded }

  if RUBY_PLATFORM == 'java'
    describe '#initialize' do
      it 'validates path' do
        expect { adaptor_class.new('/notadirectory') }.to raise_error ArgumentError, /Invalid path:/
        expect { adaptor_class.new('/') }.not_to raise_error
      end
    end

    let(:path) { Dir.mktmpdir('neo4jrb_embedded_adaptor_spec') }
    let(:adaptor) { adaptor_class.new(path) }

    before { adaptor.connect }

    it_behaves_like 'Neo4j::Core::CypherSession::Adaptor'
  else
    it 'should raise an error' do
      expect { adaptor_class.new('/') }.to raise_error 'JRuby is required for embedded mode'
    end
  end
end
