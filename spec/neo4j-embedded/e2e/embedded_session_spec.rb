require 'spec_helper'

module Neo4j::Embedded

  describe 'EmbeddedSession', api: :embedded do

    let(:open_session) do
      session = Neo4j::Session.open(:embedded_db, EMBEDDED_DB_PATH)
      session.start
      session
    end

    after(:all) do
      Neo4j::Session.current && Neo4j::Session.current.close
    end

    it_behaves_like "Neo4j::Session"

  end

  describe 'EmbeddedSession', api: :embedded do

    let(:session) do
      Neo4j::Session.current || Neo4j::Session.open(:embedded_db, EMBEDDED_DB_PATH)
    end


    describe 'db_location' do
      it "returns the location of the database" do
        session.db_location.should == EMBEDDED_DB_PATH
      end
    end

    describe 'start' do

      before do
        Neo4j::Session.current &&  Neo4j::Session.current.close
      end

      it 'starts the database' do
        session.start
        session.running?.should be_true
      end

      it "raise an error if session already was started" do
        session.start
        session.running?.should be_true
        expect{ session.start }.to raise_error
      end

      it 'is allowed to start the session after it has been shutdown' do
        session.start
        session.shutdown
        session.running?.should be_false
        session.start
        session.running?.should be_true
      end
    end


    describe 'shutdown' do
      before do
        Neo4j::Session.current &&  Neo4j::Session.current.close
      end

      it 'starts the database' do
        session.start
        session.running?.should be_true
        session.shutdown
        session.running?.should be_false
      end

      it 'ok to shutdown twice' do
        session.start
        session.shutdown
        session.running?.should be_false
        session.shutdown
        session.running?.should be_false
      end
    end

    describe '_query' do
      before(:all) do
        Neo4j::Session.current || Neo4j::Session.open(:embedded_db, EMBEDDED_DB_PATH)
        Neo4j::Session.current.start unless Neo4j::Session.current.running?
      end

      it "returns a raw Neo4j Iterator" do
        r = session._query('START n=node(0) RETURN n')
        all = r.to_a # only allowed to traverse once
        all.count.should == 1
        all.first.should include(:n)
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