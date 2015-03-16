require 'spec_helper'

describe Neo4j::Session do
  let(:session) { Neo4j::Session.new }
  let(:error) { 'not impl.' }
  it 'raises errors for methods not implemented' do
    [-> { session.start }, -> { session.shutdown }, -> { session.db_type }, -> { session.begin_tx }].each do |l|
      expect { l.call }.to raise_error error
    end

    expect { session.query }.to raise_error 'not implemented, abstract'
    expect { session._query }.to raise_error 'not implemented'
    expect { Neo4j::Session.open(:foo) }.to raise_error Neo4j::Session::InitializationError
  end
end
