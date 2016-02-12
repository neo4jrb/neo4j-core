require 'spec_helper'

module Neo4j
  module Embedded
    describe 'EmbeddedSession', api: :embedded do
      let(:open_session) do
        session = create_embedded_session
        session.start
        session
      end

      after(:all) do
        Neo4j::Session.current && Neo4j::Session.current.close
      end

      it_behaves_like 'Neo4j::Session'
    end

    describe 'EmbeddedSession', api: :embedded do
      let(:session) do
        Neo4j::Session.current || create_embedded_session
      end


      describe 'db_location' do
        it 'returns the location of the database' do
          expect(session.db_location).to eq(EMBEDDED_DB_PATH)
        end
      end

      describe 'start' do
        before do
          Neo4j::Session.current && Neo4j::Session.current.close
        end

        it 'starts the database' do
          session.start
          expect(session.running?).to be true
        end

        it 'raise an error if session already was started' do
          session.start
          expect(session.running?).to be true
          expect { session.start }.to raise_error(Neo4j::Embedded::EmbeddedSession::Error)
        end

        it 'is allowed to start the session after it has been shutdown' do
          session.start
          session.shutdown
          expect(session.running?).to be false
          session.start
          expect(session.running?).to be true
        end
      end


      describe 'shutdown' do
        before do
          Neo4j::Session.current && Neo4j::Session.current.close
        end

        it 'starts the database' do
          session.start
          expect(session.running?).to be true
          session.shutdown
          expect(session.running?).to be false
        end

        it 'ok to shutdown twice' do
          session.start
          session.shutdown
          expect(session.running?).to be false
          session.shutdown
          expect(session.running?).to be false
        end
      end

      describe 'label' do
        it 'by default map the result to single column of nodes' do
          @jimmy = Neo4j::Node.create({name: 'jimmy', age: 42}, :person)
          result = session.query.match(n: :person).return(n: [:name, :age]).to_a
          expect(result.first).to respond_to('n.name')
          expect(result.first).to respond_to('n.age')
        end
      end

      describe '_query' do
        before(:all) do
          Neo4j::Session.current || create_embedded_session
          Neo4j::Session.current.start unless Neo4j::Session.current.running?
        end

        it 'returns a raw Neo4j Iterator' do
          result = session.query.create('n').return('ID(n) AS id').to_a
          id = result.first[:id]

          r = session._query("START n=node(#{id}) RETURN n")
          all = r.to_a # only allowed to traverse once
          expect(all.count).to eq(1)
          expect(all.first).to include('n')
        end
      end
    end
  end
end
