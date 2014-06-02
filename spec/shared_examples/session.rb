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

    describe 'find_nodes' do
      before do
        session.query("CREATE (n:label { name : 'test', id: 2, version: 1.1 })")
      end

      after do
        session.query("MATCH (n:`label`) DELETE n")
      end

      def verify(node)
        node[:id].should == 2
        node[:name].should == "test"
        node[:version].should == 1.1
      end

      it 'allows finding nodes by a key with a Fixnum value' do
        node = session.find_nodes(:label, :id, 2).first
        verify node
      end

      it 'allows finding nodes by a key with a String value' do
        node = session.find_nodes(:label, :name, "test").first
        verify node
      end

      it 'allows finding nodes by a key with a Float value' do
        node = session.find_nodes(:label, :version, 1.1).first
        verify node
      end
    end

    describe 'query' do
      before(:all) do
        open_session unless Neo4j::Session.current
        @jimmy = Neo4j::Node.create({name: 'jimmy', age: 42}, :person)
        @andreas = Neo4j::Node.create({name: 'andreas', age: 20}, :person)
        @andreas_jimmy_rel = @andreas.create_rel(:friends, @jimmy)

        r = Random.new
        @label = ("R3" + r.rand(0..1000000).to_s).to_sym
        @kalle = Neo4j::Node.create({name: 'kalle', age: 4}, @label)
        @andreas2 = Neo4j::Node.create({name: 'andreas', age: 2}, @label)
        @andreas1 = Neo4j::Node.create({name: 'andreas', age: 1}, @label)
        @zebbe = Neo4j::Node.create({name: 'zebbe', age: 3}, @label)
      end


      describe 'finds with :conditions' do
        it 'finds all nodes matching condition' do
          result = Neo4j::Session.query(label: @label, conditions: {name: 'andreas'}).to_a
          result.should =~ [@andreas1, @andreas2]
          result.count.should == 2
        end

        it 'supports regex condition' do
          result = Neo4j::Session.query(label: @label, conditions: {name: /AND.*/i}).to_a
          result.should include(@andreas1, @andreas2)
          result.count.should == 2
        end

        it 'returns all nodes if no conditions' do
          result = Neo4j::Session.query(label: @label).to_a
          result.should include(@kalle, @andreas2, @andreas1, @zebbe)
          result.count.should == 4

          result = Neo4j::Session.query(label: @label, conditions: {}).to_a
          result.should include(@kalle, @andreas2, @andreas1, @zebbe)
          result.count.should == 4
        end

        it 'returns a empty enumerable if not match condition' do
          Neo4j::Session.query(label: @label, conditions: {name: 'andreas42'}).count.should == 0
          Neo4j::Session.query(label: @label, conditions: {namqe: 'andreas'}).count.should == 0
        end

        #it 'does a greater than query for .gt keys' do
        #  pending
        #  # Not sure about this query syntax using a Hash, but this is a bit similar to mongoid API
        #  # Maybe it was better like it was in the old neo4j-core API with a fluent API instead
        #  result = Neo4j::Session.query(label: @label, conditions: {:age => {gt: 18, lt: 4}})
        #end
      end

      describe 'finds with :match' do
        before(:all) do
          r = Random.new
          @label = ("R3" + r.rand(0..1000000).to_s).to_sym
          @kalle = Neo4j::Node.create({name: 'kalle', age: 4}, @label)
          @andreas2 = Neo4j::Node.create({name: 'andreas', age: 2}, @label)
          @andreas1 = Neo4j::Node.create({name: 'andreas', age: 1}, @label)
        end

        subject { Neo4j::Session.query(label: @label, match: match, conditions: {name: 'kalle'}) }

        let(:match) { ['n-[:friend]-o'] }
        context 'no relationship' do
          its(:count) { should == 0 }
        end

        context 'a relationship' do
          before(:each) do
            Neo4j::Relationship.create(:friend, @kalle, @andreas2)
          end

          it { should include(@kalle) }

          context 'correct direction' do
            let(:match) { ['n-[:friend]->o'] }
            it { should include(@kalle) }
          end

          context 'incorrect direction' do
            let(:match) { ['n<-[:friend]-o'] }
            its(:count) { should == 0 }
          end

          describe 'with string input' do
            context 'correct direction' do
              let(:match) { 'n-[:friend]->o' }
              it { should include(@kalle) }
            end

            context 'incorrect direction' do
              let(:match) { 'n<-[:friend]-o' }
              its(:count) { should == 0 }
            end
          end

          context 'integer input' do
            let(:match) { 1 }
            it 'raises error' do
              expect { subject }.to raise_error(Neo4j::Core::QueryBuilder::InvalidQueryError)
            end
          end

        end
      end

      describe 'sort' do
        it 'sorts with: order: :name' do
          result = Neo4j::Session.query(label: @label, order: :name).to_a
          result.count.should == 4
          result.to_a.map { |n| n[:name] }.should == %w[andreas andreas kalle zebbe]
        end

        it 'sorts with: order: [:name, :age]' do
          result = Neo4j::Session.query(label: @label, order: [:name, :age]).to_a
          result.count.should == 4
          result.map { |n| n[:name] }.should == %w[andreas andreas kalle zebbe]
          result.map { |n| n[:age] }.should == [1, 2, 4, 3]
        end

        it 'sorts with: order: [:name, :age]' do
          result = Neo4j::Session.query(label: @label, order: [:name, :age]).to_a
          result.count.should == 4
          result.map { |n| n[:name] }.should == %w[andreas andreas kalle zebbe]
          result.map { |n| n[:age] }.should == [1, 2, 4, 3]
        end

        it 'sorts with order: {name: :desc}' do
          result = Neo4j::Session.query(label: @label, order: {name: :desc}).to_a
          result.map { |n| n[:name] }.should == %w[zebbe kalle andreas andreas]

          result = Neo4j::Session.query(label: @label, order: {name: :asc})
          result.map { |n| n[:name] }.should == %w[andreas andreas kalle zebbe]
        end

        it 'sorts with order: [:name, {age: :desc}]' do
          result = Neo4j::Session.query(label: @label, order: [:name, {age: :desc}]).to_a
          result.map { |n| n[:name] }.should == %w[andreas andreas kalle zebbe]
          result.map { |n| n[:age] }.should == [2, 1, 4, 3]

          result = Neo4j::Session.query(label: @label, order: [:name, {age: :asc}]).to_a
          result.map { |n| n[:name] }.should == %w[andreas andreas kalle zebbe]
          result.map { |n| n[:age] }.should == [1, 2, 4, 3]
        end

      end

      describe 'limit' do
        it 'limits number of results returned' do
          result = Neo4j::Session.query(label: @label, limit: 2).to_a
          result.count.should == 2
        end

        it 'limits number of results returned when combined with sort' do
          result = Neo4j::Session.query(label: @label, order: :name, limit: 3).to_a
          result.map { |n| n[:name] }.should == %w[andreas andreas kalle]
          result.count.should == 3
        end
      end

      describe 'invalid cypher' do
        it 'raise Neo4j::Session::CypherError' do
          expect { session.query("QTART n=node(0) RETURN ID(n)") }.to raise_error(Neo4j::Session::CypherError)
        end
      end

      describe 'cypher parameters' do
        it 'allows {VAR_NAME}' do
          r = session.query("START n=node({my_var}) RETURN ID(n) AS id", params: {my_var: @jimmy.neo_id})
          r.first[:id].should == @jimmy.neo_id
        end
      end


      describe 'find with label' do
        it 'by default map the result to single column of nodes' do
          result = session.query(label: :person) # same as (label: :person, map_return: :id_to_node)
          result.should include(@jimmy)
        end
      end

      describe 'to_s' do
        it "has a to_s method" do
          session.query(label: :foobar).to_s.should start_with("MATCH (n:`foobar`) RETURN")
        end
      end

      describe 'find with where' do
        it 'accepts cypher parameters' do
          n = Neo4j::Node.create({name: 'kallekula'}, :person)
          r = session.query(label: :person, where: 'n.name={a_name}', params: {a_name: 'kallekula'})
          r.should include(n)
        end
      end

      describe 'return' do
        describe 'label: :person, return: [:name, :age]' do
          it 'returns two properties in a hash' do
            result = session.query(label: :person, return: [:name, :age])
            result.first.should have_key(:name)
            result.first.should have_key(:age)
          end
        end

        describe 'label: :person, return: :name' do
          it 'returns only the name in an Enumerable' do
            result = session.query(label: :person, return: :name)
            result.should include('jimmy')
          end
        end

        describe 'label: :person, return: "n.age as somethingelse"' do
          it 'returns only the name in an Enumerable' do
            result = session.query(label: :person, return: "n.age as somethingelse")
            result.first.should have_key(:somethingelse)
          end
        end

        describe 'label: :person' do
          it "returns Neo4j::Node enumerable" do
            result = session.query(label: :person)
            result.should include(@jimmy)
          end
        end
      end

      describe 'map_return' do
        describe "START n=node(42) RETURN n.name, n.age" do
          it 'returns an Enumerable of hashes for each row' do
            id = @jimmy.neo_id
            result = session.query("START n=node(#{id}) RETURN n.name, n.age").to_a
            result.first[:'n.name'].should == 'jimmy'
            result.first[:'n.age'].should == 42
          end
        end

        describe 'START n=node(42) RETURN n.name", map_return: :value' do
          it 'uses the first column value (n.name) in the Enumerable instead of a hash' do
            result = session.query("START n=node(#{@jimmy.neo_id}) RETURN n.name", map_return: :value)
            result.first.should == 'jimmy'
          end
        end


        describe "label: :person, return: 'ID(n)', map_return: :value" do
          it 'returns the id of the nodes in an Enumerable' do
            result = session.query(label: :person, return: 'ID(n)', map_return: :value)
            result.should include(@jimmy.neo_id)
          end
        end


        describe 'START n=relationship(43) RETURN ID(n)", map_return: :id_to_rel' do
          it 'can map and load Neo4j::Relationships' do
            result = session.query("START n=relationship(#{@andreas_jimmy_rel.neo_id}) RETURN ID(n)", map_return: :id_to_rel)
            rel = result.first
            rel.should respond_to(:start_node)
            rel.should respond_to(:end_node)
#            rel.rel_type.should == :friends TODO
            rel.should == @andreas_jimmy_rel
          end
        end

        describe 'label: :person, return: :age, map_return: :age_times_two, map_return_procs: {age_times_two: ->(row){(row || 0) *2}}' do
          it 'uses the age property and maps it' do
            result = session.query(label: :person, return: :age, map_return: :age_times_two, map_return_procs: {age_times_two: ->(row){(row || 0) *2}})
            result.to_a.should include(84,40) # age 20 and 42 times two
          end
        end

        it 'can map several column values' do
          a = Neo4j::Node.create({name: 'a'}, :laijban)
          b = Neo4j::Node.create({name: 'b'}, :laijban)
          r = a.create_rel(:knows, b)
          result = Neo4j::Session.query("START a=node(#{a.neo_id}) MATCH (a)-[r]-(b) RETURN ID(a) as A, ID(r) as R", map_return: {A: :id_to_node, R: :id_to_rel}).first

          result[:A].should == a
          result[:R].should == r
        end

        it "can create nodes and retrieve a node" do
          result = session.query("CREATE (n) RETURN ID(n) AS id", map_return: :value)
          created_id = result.first
          result = session.query("START n=node(#{created_id}) RETURN ID(n) AS id", map_return: :value)
          retrieved_id = result.first
          created_id.should == retrieved_id
        end


      end
    end

  end


end
