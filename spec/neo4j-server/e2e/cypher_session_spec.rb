require 'spec_helper'

module Neo4j::Server


  describe CypherSession do

    after do
      @session && @session.close
    end

    after(:all) do
      clean_server_db
    end

    describe 'for a created session' do
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



    describe '_query' do

      before do
        @session = CypherDatabase.connect("http://localhost:7474")
      end

      it 'returns a result containing data,columns and error?' do
        result = @session._query("START n=node(0) RETURN ID(n)")
        result.data.should == [[0]]
        result.columns.should == ['ID(n)']
        result.error?.should be_false
      end

      it "allows you to specify parameters" do
        result = @session._query("START n=node({myparam}) RETURN ID(n)", myparam: 0)
        result.data.should == [[0]]
        result.columns.should == ['ID(n)']
        result.error?.should be_false
      end

      it 'returns error codes if not a valid cypher query' do
        result = @session._query("SSTART n=node(0) RETURN ID(n)")
        result.error?.should be_true
        result.error_msg.should =~ /Invalid input/
        result.error_status.should == 'SyntaxException'
        result.error_code.should_not be_empty
      end
    end
  end

end