# Requires that an `adapter` let variable exist with the connected adapter
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adapter' do
  let(:real_session) do
    expect(adapter).to receive(:connect)
    Neo4j::Core::CypherSession.new(adapter)
  end
  let(:session_double) { double('session', adapter: adapter) }
  # TODO: Test cypher errors

  before { adapter.query(session_double, 'MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n, r') }

  subject { adapter }

  describe '#query' do
    it 'Can make a query' do
      adapter.query(session_double, 'MERGE path=(n)-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end

    it 'can make a query with a large payload' do
      adapter.query(session_double, 'CREATE (n:Test) SET n = {props} RETURN n', props: {text: 'a' * 10_000})
    end
  end

  describe '#queries' do
    it 'allows for multiple queries' do
      result = adapter.queries(session_double) do
        append 'CREATE (n:Label1) RETURN n'
        append 'CREATE (n:Label2) RETURN n'
      end

      expect(result[0].to_a[0].n).to be_a(Neo4j::Core::Node)
      expect(result[1].to_a[0].n).to be_a(Neo4j::Core::Node)
      # Maybe should have method like adapter.returns_node_and_relationship_metadata?
      if adapter.is_a?(::Neo4j::Core::CypherSession::Adapters::HTTP) && adapter.version < '2.1.5'
        expect(result[0].to_a[0].n.labels).to eq(nil)
        expect(result[1].to_a[0].n.labels).to eq(nil)
      else
        expect(result[0].to_a[0].n.labels).to eq([:Label1])
        expect(result[1].to_a[0].n.labels).to eq([:Label2])
      end
    end

    it 'allows for building with Query API' do
      result = adapter.queries(session_double) do
        append query.create(n: {Label1: {}}).return(:n)
      end

      expect(result[0].to_a[0].n).to be_a(Neo4j::Core::Node)
      if adapter.is_a?(::Neo4j::Core::CypherSession::Adapters::HTTP) && adapter.version < '2.1.5'
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

    def get_object_by_id(id, adapter)
      first = adapter.query(session_double, 'MATCH (t:Temporary {id: {id}}) RETURN t', id: id).first
      first && first.t
    end

    it 'logs one query per query_set in transaction' do
      expect_queries(1) do
        tx = adapter.transaction(session_double)
        create_object_by_id(1, tx)
        tx.close
      end
      expect(get_object_by_id(1, adapter)).to be_a(Neo4j::Core::Node)

      expect_queries(1) do
        adapter.transaction(session_double) do |tx|
          create_object_by_id(2, tx)
        end
      end
      expect(get_object_by_id(2, adapter)).to be_a(Neo4j::Core::Node)
    end

    it 'allows for rollback' do
      expect_queries(1) do
        tx = adapter.transaction(session_double)
        create_object_by_id(3, tx)
        tx.mark_failed
        tx.close
      end
      expect(get_object_by_id(3, adapter)).to be_nil

      expect_queries(1) do
        adapter.transaction(session_double) do |tx|
          create_object_by_id(4, tx)
          tx.mark_failed
        end
      end
      expect(get_object_by_id(4, adapter)).to be_nil

      expect_queries(1) do
        expect do
          adapter.transaction(session_double) do |tx|
            create_object_by_id(5, tx)
            fail 'Failing transaction with error'
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(5, adapter)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(1) do
        adapter.transaction(session_double) do |_tx|
          expect do
            adapter.transaction(session_double) do |tx|
              create_object_by_id(6, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(6, adapter)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of inner transaction
      expect_queries(2) do
        adapter.transaction(session_double) do |tx|
          create_object_by_id(7, tx)
          expect do
            adapter.transaction(session_double) do |tx|
              create_object_by_id(8, tx)
              fail 'Failing transaction with error'
            end
          end.to raise_error 'Failing transaction with error'
        end
      end
      expect(get_object_by_id(7, adapter)).to be_nil
      expect(get_object_by_id(8, adapter)).to be_nil

      # Nested transaction, error from inside inner transaction handled outside of outer transaction
      expect_queries(1) do
        expect do
          adapter.transaction(session_double) do |_tx|
            adapter.transaction(session_double) do |tx|
              create_object_by_id(9, tx)
              fail 'Failing transaction with error'
            end
          end
        end.to raise_error 'Failing transaction with error'
      end
      expect(get_object_by_id(9, adapter)).to be_nil
    end
    # it 'does not allow transactions in the wrong order' do
    #   expect { adapter.end_transaction }.to raise_error(RuntimeError, /Cannot close transaction without starting one/)
  end

  describe 'results' do
    it 'handles array results' do
      result = adapter.query(session_double, "CREATE (a {b: 'c'}) RETURN [a] AS arr")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:arr]).to be_a(Array)
      expect(result.hashes[0][:arr][0]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:arr][0].properties).to eq(b: 'c')
    end

    it 'handles map results' do
      result = adapter.query(session_double, "CREATE (a {b: 'c'}) RETURN {foo: a} AS map")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:map]).to be_a(Hash)
      expect(result.hashes[0][:map][:foo]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:map][:foo].properties).to eq(b: 'c')
    end

    it 'handles map results with arrays' do
      result = adapter.query(session_double, "CREATE (a {b: 'c'}) RETURN {foo: [a]} AS map")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:map]).to be_a(Hash)
      expect(result.hashes[0][:map][:foo]).to be_a(Array)
      expect(result.hashes[0][:map][:foo][0]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:map][:foo][0].properties).to eq(b: 'c')
    end

    it 'symbolizes keys for Neo4j objects' do
      result = adapter.query(session_double, 'RETURN {a: 1} AS obj')

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

        subject { adapter.query(session_double, query, {}, wrap_level: wrap_level).to_a[0].result }

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
        adapter.query(real_session, "CREATE (:Album {uuid: 'dup'})").to_a
        expect do
          adapter.query(real_session, "CREATE (:Album {uuid: 'dup'})").to_a
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
      subject { adapter.constraints(real_session) }

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
      subject { adapter.indexes(real_session) }

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
