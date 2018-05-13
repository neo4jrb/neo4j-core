if RUBY_PLATFORM == 'java'
  require 'spec_helper'
  require 'neo4j/core/cypher_session/adaptors/embedded'
  require './spec/neo4j/core/shared_examples/adaptor'
  require 'tmpdir'
  require 'neo4j-community'

  describe Neo4j::Core::CypherSession::Adaptors::Embedded do
    let(:adaptor_class) { Neo4j::Core::CypherSession::Adaptors::Embedded }

    describe '#initialize' do
      it 'validates path' do
        expect { adaptor_class.new('./spec/fixtures/notadirectory') }.to raise_error ArgumentError, /Invalid path:/
        expect { adaptor_class.new('./spec/fixtures/adirectory') }.not_to raise_error
      end
    end

    before(:all) do
      path = Dir.mktmpdir('neo4jrb_embedded_adaptor_spec')
      @adaptor = Neo4j::Core::CypherSession::Adaptors::Embedded.new(path)
      @adaptor.connect
    end

    let(:adaptor) { @adaptor }

    it_behaves_like 'Neo4j::Core::CypherSession::Adaptor'
  end
end
