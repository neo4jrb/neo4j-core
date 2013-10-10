require 'spec_helper'

module Neo4j::Embedded

  describe 'EmbeddedSession', api: :embedded do
    before(:all) do
      @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
      @session.start
    end

    after(:all) do
      @session && @session.close
    end

    it_behaves_like "Neo4j::Session"

  end

  describe 'EmbeddedSession', api: :embedded do


    describe 'connect' do
      after(:each) do
        @session && @session.close
      end

      it 'unregister the session when it is closed' do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        Neo4j::Session.current.should == @session
        @session.close
        Neo4j::Session.current.should be_nil
      end

      it 'is created by connecting to the database' do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        @session.should be_a_kind_of(Neo4j::Session)
      end

      it 'sets it as the current session' do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        Neo4j::Session.current.should == @session
      end
    end

    describe 'start' do
      after(:each) do
        @session && @session.close
      end

      it 'starts the database' do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        @session.start
        @session.running?.should be_true
      end

      it "raise an error if session already was started" do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        @session.start
        expect{ @session.start }.to raise_error
      end

      it 'is allowed to start the session after it has been shutdown' do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        @session.start
        @session.shutdown
        @session.running?.should be_false
        @session.start
        @session.running?.should be_true
      end
    end


    describe 'shutdown' do
      after(:each) do
        @session && @session.close
      end

      it 'starts the database' do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        @session.start
        @session.running?.should be_true
        @session.shutdown
        @session.running?.should be_false
      end

      it 'ok to shutdown twice' do
        @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
        @session.start
        @session.shutdown
        @session.running?.should be_false
        @session.shutdown
        @session.running?.should be_false
      end
    end

    #describe 'create_node' do
    #  before(:each) do
    #    @session = EmbeddedDatabase.connect(EMBEDDED_DB_PATH)
    #    @session.start
    #  end
    #
    #  it 'can create a node' do
    #    tx = Neo4j::Transaction.run do
    #      n = Neo4j::Node.create name: 'jimmy'
    #      n[:kalle] = 'foo'
    #      n[:kalle].should == 'foo'
    #    end
    #  end
    #end
  end

end