RSpec.shared_examples "Neo4j::Session" do

  describe 'open and close' do
    before { Neo4j::Session.current && Neo4j::Session.current.close}
    after { Neo4j::Session.current && Neo4j::Session.current.close}

    it 'stores the current session in Neo4j::Session.current' do
      session = open_session
      expect(Neo4j::Session.current).to eq(session)
      session.close
      expect(Neo4j::Session.current).to be_nil
    end

    it 'creates a Neo4j::Session' do
      session = open_session
      expect(session).to be_a_kind_of(Neo4j::Session)
    end
  end

  describe 'with a open session' do

    describe 'find_nodes' do
      before do
        session.query.create(n: {label: {name: 'test', id: 2, version: 1.1}}).exec
      end

      after do
        session.query.match(n: :label).delete(:n).exec
      end

      def verify(node)
        expect(node[:id]).to eq(2)
        expect(node[:name]).to eq("test")
        expect(node[:version]).to eq(1.1)
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
          result = Neo4j::Session.query.match(n: {@label => {name: 'andreas'}}).pluck(:n)

          expect(result).to match_array([@andreas1, @andreas2])
          expect(result.count).to eq(2)
        end

        it 'supports regex condition' do
          result = Neo4j::Session.query.match(n: @label).where(n: {name: /AND.*/i}).pluck(:n).to_a
          expect(result).to include(@andreas1, @andreas2)
          expect(result.count).to eq(2)
        end

        it 'returns all nodes if no conditions' do
          result = Neo4j::Session.query.match(n: @label).pluck(:n).to_a
          expect(result).to include(@kalle, @andreas2, @andreas1, @zebbe)
          expect(result.count).to eq(4)

          result = Neo4j::Session.query.match(n: @label).where({}).pluck(:n).to_a
          expect(result).to include(@kalle, @andreas2, @andreas1, @zebbe)
          expect(result.count).to eq(4)
        end

        it 'returns a empty enumerable if not match condition' do
          expect(Neo4j::Session.query.match(n: @label).where(n: {name: 'andreas42'}).return(:n).count).to eq(0)
          expect(Neo4j::Session.query.match(n: @label).where(n: {namqe: 'andreas'}).return(:n).count).to eq(0)
        end

        #it 'does a greater than query for .gt keys' do
        #  skip
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

        subject { Neo4j::Session.query.match(n: @label).match(match).where(n: {name: 'kalle'}).pluck(:n) }

        let(:match) { ['n-[:friend]-o'] }
        context 'no relationship' do
          its(:count) { should == 0 }
        end

        context 'a relationship' do
          before(:each) do
            Neo4j::Relationship.create(:friend, @kalle, @andreas2)
          end

          it { is_expected.to include(@kalle) }

          context 'correct direction' do
            let(:match) { ['n-[:friend]->o'] }
            it { is_expected.to include(@kalle) }
          end

          context 'incorrect direction' do
            let(:match) { ['n<-[:friend]-o'] }
            its(:count) { should == 0 }
          end

          describe 'with string input' do
            context 'correct direction' do
              let(:match) { 'n-[:friend]->o' }
              it { is_expected.to include(@kalle) }
            end

            context 'incorrect direction' do
              let(:match) { 'n<-[:friend]-o' }
              its(:count) { should == 0 }
            end
          end

          context 'integer input' do
            let(:match) { 1 }
            it 'raises error' do
              expect { subject.response }.to raise_error(ArgumentError)
            end
          end

          context 'invalid cypher' do
            let(:match) { 'n-o' }
            it 'raises error' do
              expect { subject.response }.to raise_error(Neo4j::Session::CypherError)
            end
          end

        end
      end

      describe 'sort' do
        it 'sorts with: order: :name' do
          result = Neo4j::Session.query.match(n: @label).order(n: :name).pluck(:n)
          expect(result.count).to eq(4)
          expect(result.to_a.map {|o| o[:name] }).to eq(%w[andreas andreas kalle zebbe])
        end

        it 'sorts with: order: [:name, :age]' do
          result = Neo4j::Session.query.match(n: @label).order(n: [:name, :age]).pluck(:n)
          expect(result.count).to eq(4)
          expect(result.map {|o| o[:name] }).to eq(%w[andreas andreas kalle zebbe])
          expect(result.map {|o| o[:age] }).to eq([1, 2, 4, 3])
        end

        it 'sorts with order: {name: :desc}' do
          result = Neo4j::Session.query.match(n: @label).order(n: {name: :desc}).pluck(:n)
          expect(result.map {|o| o[:name] }).to eq(%w[zebbe kalle andreas andreas])

          result = Neo4j::Session.query.match(n: @label).order(n: {name: :asc}).pluck(:n)
          expect(result.map {|o| o[:name] }).to eq(%w[andreas andreas kalle zebbe])
        end

        it 'sorts with order: [:name, {age: :desc}]' do
          result = Neo4j::Session.query.match(n: @label).order(n: [:name, {age: :desc}]).pluck(:n)
          expect(result.map {|o| o[:name] }).to eq(%w[andreas andreas kalle zebbe])
          expect(result.map {|o| o[:age] }).to eq([2, 1, 4, 3])

          result = Neo4j::Session.query.match(n: @label).order(n: [:name, {age: :asc}]).pluck(:n)
          expect(result.map {|o| o[:name] }).to eq(%w[andreas andreas kalle zebbe])
          expect(result.map {|o| o[:age] }).to eq([1, 2, 4, 3])
        end

      end

      describe 'limit' do
        it 'limits number of results returned' do
          result = Neo4j::Session.query.match(n: @label).return(:n).limit(2).to_a
          expect(result.count).to eq(2)
        end

        it 'limits number of results returned when combined with sort' do
          result = Neo4j::Session.query.match(n: @label).order(n: :name).limit(3).pluck(:n)
          expect(result.map {|o| o[:name] }).to eq(%w[andreas andreas kalle])
          expect(result.count).to eq(3)
        end
      end

      describe 'invalid cypher' do
        it 'raise Neo4j::Server::CypherResponse::ResponseError' do
          expect { session.query.start("n=nuode(0)").return("ID(n)").response }.to raise_error(Neo4j::Session::CypherError)
        end
      end

      describe 'cypher parameters' do
        it 'allows {VAR_NAME}' do
          r = session.query.start(n: 'node({my_var})').return("ID(n) AS id").params(my_var: @jimmy.neo_id)
          expect(r.first[:id]).to eq(@jimmy.neo_id)
        end
      end


      describe 'find with label' do
        it 'by default map the result to single column of nodes' do
          result = session.query.match(n: :person).pluck(:n)
          expect(result).to include(@jimmy)
        end
      end

      describe 'find with where' do
        it 'accepts cypher parameters' do
          n = Neo4j::Node.create({name: 'kallekula'}, :person)
          r = session.query.match(n: {person: {name: '{a_name}'}}).params(a_name: 'kallekula').pluck(:n)
          expect(r).to include(n)
        end
      end

      describe 'return' do
        describe 'label: :person, return: [:name, :age]' do
          it 'returns two properties in a hash' do
            result = session.query.match(n: :person).return(n: [:name, :age])
            expect(result.first).to respond_to('n.name')
            expect(result.first).to respond_to('n.age')
          end
        end

        describe 'label: :person, return: :name' do
          it 'returns only the name in an Enumerable' do
            result = session.query.match(n: :person).pluck(n: :name)
            expect(result).to include('jimmy')
          end
        end

        describe 'label: :person, return: "n.age as somethingelse"' do
          it 'returns only the name in an Enumerable' do
            result = session.query.match(n: :person).return("n.age as somethingelse").to_a
            expect(result.first).to respond_to(:somethingelse)
          end
        end

        describe 'label: :person' do
          it "returns Neo4j::Node enumerable" do
            result = session.query.match(n: :person).pluck(:n)
            expect(result).to include(@jimmy)
          end
        end
      end

      describe 'query with string' do
        it 'allows querying with cypher strings directly' do
          n = Neo4j::Node.create({name: 'Brian', hat: 'fancy'}, :person)
          result = session.query("MATCH (n) WHERE ID(n) = #{n.neo_id} RETURN n").first
          expect(result.n[:name]).to eq('Brian')
          expect(result.n[:hat]).to eq('fancy')
        end
      end

    end

  end


end
