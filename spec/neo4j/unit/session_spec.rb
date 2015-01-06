require 'spec_helper'

describe Neo4j::Session do
  before(:all) do
    @before_session = Neo4j::Session.current
    Neo4j::Session.register_db(:dummy1_db) { 'dummy1_db' }
    Neo4j::Session.register_db(:dummy2_db) { 'dummy2_db' }
  end

  after(:all) do
    # restore the session
    Neo4j::Session.set_current(@before_session)
  end


  describe '.open' do
    it 'returns the session created' do
      s1 = Neo4j::Session.open(:dummy1_db)
      expect(s1).to eq('dummy1_db')

      s2 = Neo4j::Session.open(:dummy2_db)
      expect(s2).to eq('dummy2_db')
    end
  end

  describe '.set_current' do
    it 'sets the current session' do
      s1 = Neo4j::Session.open(:dummy1_db)
      Neo4j::Session.open(:dummy2_db)

      Neo4j::Session.set_current(s1)
      expect(Neo4j::Session.current).to eq('dummy1_db')
    end
  end
end
