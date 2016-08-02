require 'spec_helper'

describe Neo4j::Session do
  let(:session) { Neo4j::Session.new }
  let(:error) { 'not impl.' }
  it 'raises errors for methods not implemented' do
    [-> { session.start },
     -> { session.shutdown },
     -> { session.db_type }].each do |l|
      expect { l.call }.to raise_error error
    end

    expect { session.query }.to raise_error 'not implemented, abstract'
    expect { session._query }.to raise_error 'not implemented'
    expect { Neo4j::Session.open(:foo) }.to raise_error Neo4j::Session::InitializationError
  end

  describe '#on_next_session_available' do
    let(:foo) { double('Code to be executed when a session is established', called: :foo, called2: :bar) }

    context 'with no session active' do
      before { Neo4j::Session.current.close if Neo4j::Session.current }

      it 'adds the block to the listeners queue' do
        expect do
          Neo4j::Session.on_next_session_available { foo.called }
        end.to change { Neo4j::Session._listeners }
      end

      it 'does not immediately execute the contents of the block' do
        expect(foo).not_to receive(:called)
        Neo4j::Session.on_next_session_available { foo.called }
      end

      context 'on session available' do
        let(:results) { [] }
        before do
          Neo4j::Session.current.close if Neo4j::Session.current
          Neo4j::Session.on_next_session_available { results.push foo.called }
          Neo4j::Session.on_next_session_available { results.push foo.called2 }
        end

        it 'calls the block and empties the queue' do
          expect(foo).to receive(:called).exactly(1).times
          expect(foo).to receive(:called2).exactly(1).times
          expect { create_appropriate_session }.to change { Neo4j::Session._listeners.empty? }
          expect(results).to eq([:foo, :bar])
        end
      end
    end

    context 'with active session' do
      before { create_appropriate_session unless Neo4j::Session.current }

      it 'immediately calls the block without adding to the listeners queue' do
        expect(foo).to receive(:called).exactly(1).times
        expect do
          Neo4j::Session.on_next_session_available { foo.called }
        end.not_to change { Neo4j::Session._listeners }
      end
    end
  end
end
