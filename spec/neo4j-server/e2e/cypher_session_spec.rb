require 'spec_helper'

module Neo4j::Server


  describe CypherSession, api: :server do

    def open_session
      create_server_session
    end

    def open_named_session(name, default = nil)
      create_named_server_session(name, default)
    end

    it_behaves_like "Neo4j::Session"


    describe '_query' do

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
