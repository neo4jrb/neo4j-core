# Requires that an `adaptor` let variable exist with the connected adaptor
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adaptor' do
  let(:real_session) do
    expect(adaptor).to receive(:connect)
    Neo4j::Core::CypherSession.new(adaptor)
  end
  let(:session_double) { double('session', adaptor: adaptor) }
  # TODO: Test cypher errors

  before { adaptor.query(session_double, 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r') }

  subject { adaptor }

  describe '#query' do
    it 'Can make a query' do
      adaptor.query(session_double, 'MERGE path=(n)-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end

    it 'can make a query with a large payload' do
      adaptor.query(session_double, 'CREATE (n:Test) SET n = {props} RETURN n', props: {text: 'a' * 10_000})
    end
  end

  describe '#queries' do
    it 'allows for multiple queries' do
      result = adaptor.queries(session_double) do
        append 'CREATE (n:Label1) RETURN n'
        append 'CREATE (n:Label2) RETURN n'
      end

      expect(result[0].to_a[0].n).to be_a(Neo4j::Core::Node)
      expect(result[1].to_a[0].n).to be_a(Neo4j::Core::Node)
      # Maybe should have method like adaptor.returns_node_and_relationship_metadata?
      if adaptor.is_a?(::Neo4j::Core::CypherSession::Adaptors::HTTP) && adaptor.version < '2.1.5'
        expect(result[0].to_a[0].n.labels).to eq(nil)
        expect(result[1].to_a[0].n.labels).to eq(nil)
      else
        expect(result[0].to_a[0].n.labels).to eq([:Label1])
        expect(result[1].to_a[0].n.labels).to eq([:Label2])
      end
    end

    it 'fails correctly on failing queries' do
      expect do
        adaptor.queries(session_double) do
          append 'CREATE (n:Label1:) RETURN n'
          append 'CREATE (n:Label2) RETURN n'
        end
      end.to raise_error Neo4j::Core::CypherSession::CypherError, /SyntaxError/
    end

    it 'allows for building with Query API' do
      result = adaptor.queries(session_double) do
        append query.create(n: {Label1: {}}).return(:n)
      end

      expect(result[0].to_a[0].n).to be_a(Neo4j::Core::Node)
      if adaptor.is_a?(::Neo4j::Core::CypherSession::Adaptors::HTTP) && adaptor.version < '2.1.5'
        expect(result[0].to_a[0].n.labels).to eq(nil)
      else
        expect(result[0].to_a[0].n.labels).to eq([:Label1])
      end
    end
  end

  describe 'transactions' do
    def create_object_by_id(id, tx)
      tx.query('CREATE (t:Temporary {id: {id}})', id: id)
    end

    def get_object_by_id(id, adaptor)
      first = adaptor.query(session_double, 'MATCH (t:Temporary {id: {id}}) RETURN t', id: id).first
      first && first.t
    end

    it 'logs one query per query_set in transaction' do
      expect_queries(1) do
        tx = adaptor.transaction(session_double)
        create_object_by_id(1, tx)
        tx.close
      end
      expect(get_object_by_id(1, adaptor)).to be_a(Neo4j::Core::Node)

      expect_queries(1) do
        adaptor.transaction(session_double) do |tx|
          create_object_by_id(2, tx)
        end
      end
      expect(get_object_by_id(2, adaptor)).to be_a(Neo4j::Core::Node)
    end

    it 'allows for rollback' do
      expect_queries(1) do
        tx = adaptor.transaction(session_double)
        create_object_by_id(3, tx)
        tx.mark_failed
        tx.close
      end
      expect(get_object_by_id(3, adaptor)).to be_nil

      expect_queries(1) do
        adaptor.transaction(session_double) do |tx|
          create_object_by_id(4, tx)
          tx.mark_failed
        end
      end
      expect(get_object_by_id(4, adaptor)).to be_nil

      expect_queries(1) do
        expect do
          adaptor.transaction(session_double) do |tx|
            create_object_by_id(5, tx)
            fail 'Failing transaction with error'
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(5, adaptor)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(1) do
        adaptor.transaction(session_double) do |_tx|
          expect do
            adaptor.transaction(session_double) do |tx|
              create_object_by_id(6, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(6, adaptor)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(2) do
        adaptor.transaction(session_double) do |tx|
          create_object_by_id(7, tx)
          expect do
            adaptor.transaction(session_double) do |tx|
              create_object_by_id(8, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(7, adaptor)).to be_nil
      expect(get_object_by_id(8, adaptor)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of outer transaction
      expect_queries(1) do
        expect do
          adaptor.transaction(session_double) do |_tx|
            adaptor.transaction(session_double) do |tx|
              create_object_by_id(9, tx)
              fail 'Failing transaction with error'
            end
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(9, adaptor)).to be_nil
    end
    # it 'does not allow transactions in the wrong order' do
    #   expect { adaptor.end_transaction }.to raise_error(RuntimeError, /Cannot close transaction without starting one/)
  end

  describe 'results' do
    it 'handles array results' do
      result = adaptor.query(session_double, "CREATE (a {b: 'c'}) RETURN [a] AS arr")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:arr]).to be_a(Array)
      expect(result.hashes[0][:arr][0]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:arr][0].properties).to eq(b: 'c')
    end

    it 'handles map results' do
      result = adaptor.query(session_double, "CREATE (a {b: 'c'}) RETURN {foo: a} AS map")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:map]).to be_a(Hash)
      expect(result.hashes[0][:map][:foo]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:map][:foo].properties).to eq(b: 'c')
    end

    it 'handles map results with arrays' do
      result = adaptor.query(session_double, "CREATE (a {b: 'c'}) RETURN {foo: [a]} AS map")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:map]).to be_a(Hash)
      expect(result.hashes[0][:map][:foo]).to be_a(Array)
      expect(result.hashes[0][:map][:foo][0]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:map][:foo][0].properties).to eq(b: 'c')
    end

    it 'symbolizes keys for Neo4j objects' do
      result = adaptor.query(session_double, 'RETURN {a: 1} AS obj')

      expect(result.hashes).to eq([{obj: {a: 1}}])

      structs = result.structs
      expect(structs).to be_a(Array)
      expect(structs.size).to be(1)
      expect(structs[0].obj).to eq(a: 1)
    end

    context 'wrapper class exists' do
      before do
        stub_const 'WrapperClass', (Class.new do
          attr_reader :wrapped_object

          def initialize(obj)
            @wrapped_object = obj
          end
        end)

        Neo4j::Core::Node.wrapper_callback(->(obj) { WrapperClass.new(obj) })
        Neo4j::Core::Relationship.wrapper_callback(->(obj) { WrapperClass.new(obj) })
        Neo4j::Core::Path.wrapper_callback(->(obj) { WrapperClass.new(obj) })
      end

      after do
        Neo4j::Core::Node.clear_wrapper_callback
        Neo4j::Core::Path.clear_wrapper_callback
        Neo4j::Core::Relationship.clear_wrapper_callback
      end

      # Normally I don't think you wouldn't wrap nodes/relationships/paths
      # with the same class.  It's just expedient to do so in this spec

      describe 'wrapping' do
        let(:query) do
          "MERGE path=(n:Foo {a: 1})-[r:foo {b: 2}]->(b:Foo)
           RETURN #{return_clause} AS result"
        end

        # Default wrap_level should be :core_entity
        let(:wrap_level) { nil }

        subject { adaptor.query(session_double, query, {}, wrap_level: wrap_level).to_a[0].result }

        let_context return_clause: 'n' do
          it { should be_a(Neo4j::Core::Node) }
          its(:properties) { should eq(a: 1) }
        end

        let_context return_clause: 'r' do
          it { should be_a(Neo4j::Core::Relationship) }
          its(:properties) { should eq(b: 2) }
        end

        let_context return_clause: 'path' do
          it { should be_a(Neo4j::Core::Path) }
        end

        let_context return_clause: '{c: 3}' do
          it { should eq(c: 3) }
        end

        # Possible to return better data structure for :none?
        let_context wrap_level: :none do
          let_context return_clause: 'n' do
            it { should eq(a: 1) }
          end

          let_context return_clause: 'r' do
            it { should eq(b: 2) }
          end

          let_context return_clause: 'path' do
            it { should eq([{a: 1}, {b: 2}, {}]) }
          end

          let_context return_clause: '{c: 3}' do
            it { should eq(c: 3) }
          end
        end

        let_context wrap_level: :proc do
          let_context return_clause: 'n' do
            it { should be_a(WrapperClass) }
            its(:wrapped_object) { should be_a(Neo4j::Core::Node) }
            its(:'wrapped_object.properties') { should eq(a: 1) }
          end

          let_context return_clause: 'r' do
            it { should be_a(WrapperClass) }
            its(:wrapped_object) { should be_a(Neo4j::Core::Relationship) }
            its(:'wrapped_object.properties') { should eq(b: 2) }
          end

          let_context return_clause: 'path' do
            it { should be_a(WrapperClass) }
            its(:wrapped_object) { should be_a(Neo4j::Core::Path) }
          end

          let_context return_clause: '{c: 3}' do
            it { should eq(c: 3) }
          end
        end
      end
    end
  end

  describe 'cypher errors' do
    before { delete_schema(real_session) }
    before do
      create_constraint(real_session, :Album, :uuid, type: :unique)
    end

    describe 'unique constraint error' do
      it 'raises an error?' do
        adaptor.query(real_session, "CREATE (:Album {uuid: 'dup'})").to_a
        expect do
          adaptor.query(real_session, "CREATE (:Album {uuid: 'dup'})").to_a
        end.to raise_error(::Neo4j::Core::CypherSession::SchemaErrors::ConstraintValidationFailedError)
      end
    end
  end

  describe 'schema inspection' do
    before { delete_schema(real_session) }
    before do
      create_constraint(real_session, :Album, :al_id, type: :unique)
      create_constraint(real_session, :Album, :name, type: :unique)
      create_constraint(real_session, :Song, :so_id, type: :unique)

      create_index(real_session, :Band, :ba_id)
      create_index(real_session, :Band, :fisk)
      create_index(real_session, :Person, :name)
    end

    describe 'constraints' do
      let(:label) {}
      subject { adaptor.constraints(real_session) }

      it do
        should match_array([
                             {type: :uniqueness, label: :Album, properties: [:al_id]},
                             {type: :uniqueness, label: :Album, properties: [:name]},
                             {type: :uniqueness, label: :Song, properties: [:so_id]}
                           ])
      end
    end

    describe 'indexes' do
      let(:label) {}
      subject { adaptor.indexes(real_session) }

      it do
        should match_array([
                             a_hash_including(label: :Band, properties: [:ba_id]),
                             a_hash_including(label: :Band, properties: [:fisk]),
                             a_hash_including(label: :Person, properties: [:name]),
                             a_hash_including(label: :Album, properties: [:al_id]),
                             a_hash_including(label: :Album, properties: [:name]),
                             a_hash_including(label: :Song, properties: [:so_id])
                           ])
      end
    end
  end
end
