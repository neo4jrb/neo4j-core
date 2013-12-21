share_examples_for "Neo4j::Session" do

  describe 'open and close' do
    before { Neo4j::Session.current && Neo4j::Session.current.close}
    after { Neo4j::Session.current && Neo4j::Session.current.close}

    it 'stores the current session in Neo4j::Session.current' do
      session = open_session
      Neo4j::Session.current.should == session
      session.close
      Neo4j::Session.current.should be_nil
    end

    it 'creates a Neo4j::Session' do
      session = open_session
      session.should be_a_kind_of(Neo4j::Session)
    end

  end

  describe 'with a open session' do

    describe 'query' do
      it 'returns data as arrays of hashs' do
        result = session.query("CREATE (n) RETURN ID(n) AS id")
        result.first[:id].should be_a(Fixnum)
      end

      it 'allows parameters for the query' do
        result = session.query("START n=node({a_parameter}) RETURN ID(n)", a_parameter: 0)
        result.to_a.count.should == 1
        result.first.should == {:'ID(n)' => 0}
      end

      it 'accepts an cypher DSL with parameters' do
        result = session.query(a_parameter: 0) { node("{a_parameter}").neo_id.as(:foo) }
        result.to_a.count.should == 1
        result.first.should == {:foo => 0}
      end

      it 'accepts an cypher DSL without parameters' do
        result = session.query("CREATE (n) RETURN ID(n) AS id")
        id = result.first[:id];
        result = session.query { node(id).neo_id.as(:foo) }
        result.to_a.count.should == 1
        result.first.should == {:foo => id}
      end

      it 'raise Neo4j::Session::CypherError for invalid cypher query' do
        expect { session.query("QTART n=node(0) RETURN ID(n)") }.to raise_error(Neo4j::Session::CypherError)
      end
    end

  end


end