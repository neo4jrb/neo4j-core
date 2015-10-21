# Requires that an initialized `adaptor` variable be available
# Requires that `setup_query_subscription` is called
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adaptor' do
  before(:all) { setup_query_subscription }

  # TODO: Test cypher errors

  after { adaptor.end_transaction if adaptor.transaction_started? }

  describe '#query' do
    it 'Can make a query' do
      adaptor.query('MERGE path=n-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end
  end

  describe '#queries' do
    it 'allows for multiple queries' do
      result = adaptor.queries do
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

    it 'allows for building with Query API' do
      result = adaptor.queries do
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
    it 'lets you execute a query in a transaction' do
      expect_queries(1) do
        adaptor.start_transaction
        adaptor.query('MATCH n RETURN n LIMIT 1')
        adaptor.end_transaction
      end

      expect_queries(1) do
        adaptor.transaction do
          adaptor.query('MATCH n RETURN n LIMIT 1')
        end
      end
    end

    it 'does not allow transactions in the wrong order' do
      expect { adaptor.end_transaction }.to raise_error(RuntimeError, /Cannot close transaction without starting one/)
    end
  end

  describe 'results' do
    it 'handles array results' do
      result = adaptor.query("CREATE (a {b: 'c'}) RETURN [a]")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:'[a]']).to be_a(Array)
      expect(result.hashes[0][:'[a]'][0]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:'[a]'][0].properties).to eq(b: 'c')
    end

    it 'symbolizes keys for Neo4j objects' do
      result = adaptor.query('RETURN {a: 1} AS obj')

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
      it 'Returns wrapped objects from results' do
        result = adaptor.query('CREATE path=(n {a: 1})-[r:foo {b: 2}]->(b) RETURN n,r,path')

        result_entity = result.hashes[0][:n]
        expect(result_entity).to be_a(WrapperClass)
        expect(result_entity.wrapped_object).to be_a(Neo4j::Core::Node)
        expect(result_entity.wrapped_object.properties).to eq(a: 1)

        result_entity = result.hashes[0][:r]
        expect(result_entity).to be_a(WrapperClass)
        expect(result_entity.wrapped_object).to be_a(Neo4j::Core::Relationship)
        expect(result_entity.wrapped_object.properties).to eq(b: 2)

        result_entity = result.hashes[0][:path]
        expect(result_entity).to be_a(WrapperClass)
        expect(result_entity.wrapped_object).to be_a(Neo4j::Core::Path)
      end
    end
  end

  describe 'schema inspection methods' do
    describe 'indexes_for_label' do
      let(:label) { "Foo#{SecureRandom.hex[0,10]}" }
      subject { adaptor.indexes_for_label(label) }

      it { should eq([]) }

      context 'index has been created' do
        before { adaptor.query("CREATE INDEX ON :#{label}(bar)") }

        it { should eq([:bar]) }

        context 'index has been dropped' do
          before { adaptor.query("DROP INDEX ON :#{label}(bar)") }

          it { should eq([]) }
        end
      end
    end

    describe 'uniqueness_constraints_for_label' do
      let(:label) { "Foo#{SecureRandom.hex[0,10]}" }
      subject { adaptor.uniqueness_constraints_for_label(label) }

      it { should eq([]) }

      context 'constraint has been created' do
        before { adaptor.query("CREATE CONSTRAINT ON (n:#{label}) ASSERT n.bar IS UNIQUE") }

        it { should eq([:bar]) }

        context 'constraint has been dropped' do
          before { adaptor.query("DROP CONSTRAINT ON (n:#{label}) ASSERT n.bar IS UNIQUE") }

          it { should eq([]) }
        end
      end
    end
  end
end
