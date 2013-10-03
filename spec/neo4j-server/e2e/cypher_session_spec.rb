require 'spec_helper'

module Neo4j::Server


  describe CypherSession do

    after do
      @session && @session.close
    end

    after(:all) do
      clean_server_db
    end

    it 'unregister the session when it is closed' do
      @session = CypherDatabase.connect("http://localhost:7474")
      Neo4j::Session.current.should == @session
      @session.close
      Neo4j::Session.current.should be_nil
    end

    it 'is created by connecting to the database' do
      @session = CypherDatabase.connect("http://localhost:7474")
      @session.should be_a_kind_of(Neo4j::Session)
    end

    it 'sets it as the current session' do
      @session = CypherDatabase.connect("http://localhost:7474")
      Neo4j::Session.current.should == @session
    end
  end

end