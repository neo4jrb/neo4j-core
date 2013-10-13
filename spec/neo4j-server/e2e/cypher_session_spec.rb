require 'spec_helper'

module Neo4j::Server


  describe CypherSession do

    let(:open_session) do
        Neo4j::Session.open(:server_db, "http://localhost:7474")
    end

    after(:all) do
      clean_server_db
    end

    it_behaves_like "Neo4j::Session"


    describe '_query' do

      let(:session) do
        @session ||= open_session
      end
      after(:all) do
        @session.close
      end

      it 'returns a result containing data,columns and error?' do
        result = session._query("START n=node(0) RETURN ID(n)")
        result.data.should == [[0]]
        result.columns.should == ['ID(n)']
        result.error?.should be_false
      end

      it "allows you to specify parameters" do
        result = session._query("START n=node({myparam}) RETURN ID(n)", myparam: 0)
        result.data.should == [[0]]
        result.columns.should == ['ID(n)']
        result.error?.should be_false
      end

      it 'returns error codes if not a valid cypher query' do
        result = session._query("SSTART n=node(0) RETURN ID(n)")
        result.error?.should be_true
        result.error_msg.should =~ /Invalid input/
        result.error_status.should == 'SyntaxException'
        result.error_code.should_not be_empty
      end
    end
  end

end