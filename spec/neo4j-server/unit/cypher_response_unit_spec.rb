require 'spec_helper'

module Neo4j
  module Server
    describe CypherResponse do
      def hash_to_struct(response, hash)
        response.struct.new(*hash.values)
      end

      describe '#entity_data' do
        let(:without_tx_response) do
          {
            columns: ['n'],
            data: [[{labels: 'http://localhost:7474/db/data/node/625/labels',
                     outgoing_relationships: 'http://localhost:7474/db/data/node/625/relationships/out',
                     data: {'name' => 'Brian', 'hat' => 'fancy'},
                     traverse: 'http://localhost:7474/db/data/node/625/traverse/{returnType}',
                     all_typed_relationships: 'http://localhost:7474/db/data/node/625/relationships/all/{-list|&|types}',
                     property: 'http://localhost:7474/db/data/node/625/properties/{key}',
                     self: 'http://localhost:7474/db/data/node/625',
                     properties: 'http://localhost:7474/db/data/node/625/properties',
                     outgoing_typed_relationships: 'http://localhost:7474/db/data/node/625/relationships/out/{-list|&|types}',
                     incoming_relationships: 'http://localhost:7474/db/data/node/625/relationships/in',
                     extensions: {},
                     create_relationship: 'http://localhost:7474/db/data/node/625/relationships',
                     paged_traverse: 'http://localhost:7474/db/data/node/625/paged/traverse/{returnType}{?pageSize,leaseTime}',
                     all_relationships: 'http://localhost:7474/db/data/node/625/relationships/all',
                     incoming_typed_relationships: 'http://localhost:7474/db/data/node/625/relationships/in/{-list|&|types}'}]]
          }
        end


        let(:with_tx_response) do
          {
            commit: 'http://localhost:7474/db/data/transaction/153/commit',
            results: [
              {columns: ['n'],
               data: [{row: [{'name' => 'Brian', 'hat' => 'fancy'}]}]}
            ],
            transaction: {expires: 'Fri, 08 Aug 2014 11:38:39 +0000'},
            errors: []
          }
        end

        shared_examples 'a hash with data and id' do
          specify { expect(subject[:data]).to eq('name' => 'Brian', 'hat' => 'fancy') }
          specify { expect(subject[:id]).to eq(625) }
        end

        def successful_response(response)
          double('successful_response', body: response, status: 200)
        end

        context 'returns in a transaction' do
          subject do
            CypherResponse.create_with_tx(successful_response(with_tx_response)).entity_data(625)
          end

          it_behaves_like 'a hash with data and id'
        end

        context 'returns when not in a transaction' do
          subject do
            CypherResponse.create_with_no_tx(successful_response(without_tx_response)).entity_data(625)
          end

          it_behaves_like 'a hash with data and id'
        end
      end


      describe '#to_struct_enumeration' do
        it 'creates a enumerable of hash key values' do
          # result.data.should == [[0]]
          # result.columns.should == ['ID(n)']
          response = CypherResponse.new(nil, nil)
          response.set_data(data: [[0]], columns: ['ID(n)'])

          expect(response.to_struct_enumeration.to_a).to eq([hash_to_struct(response, 'ID(n)' => 0)])
        end

        it 'creates an enumerable of hash key multiple values' do
          response = CypherResponse.new(nil, nil)
          response.set_data(data: [['Romana', 126], ['The Doctor', 750]], columns: %w(name age))

          expect(response.to_struct_enumeration.to_a).to eq(
            [hash_to_struct(response, name: 'Romana', age: 126),
             hash_to_struct(response, name: 'The Doctor', age: 750)]
          )
        end
      end

      describe '#to_node_enumeration' do
        it 'returns basic values' do
          response = CypherResponse.new(nil, nil)
          response.set_data(data: [['Billy'], ['Jimmy']], columns: ['person.name'])

          expect(response.to_node_enumeration.to_a).to eq([hash_to_struct(response, 'person.name' => 'Billy'), hash_to_struct(response, 'person.name' => 'Jimmy')])
        end

        context 'with full node response' do
          let(:response) { CypherResponse.new(nil, nil) }
          let(:response_data) do
            {data:
                            [
                              [{labels: 'http://localhost:7474/db/data/node/18/labels',
                                self: 'http://localhost:7474/db/data/node/18',
                                data: {name: 'Billy', age: 20}}],
                              [{labels: 'http://localhost:7474/db/data/node/18/labels',
                                self: 'http://localhost:7474/db/data/node/19',
                                data: {name: 'Jimmy', age: 24}}]
                            ],
             columns: ['person']}
          end

          before do
            response.set_data(response_data)
          end

          let(:node_enumeration) { response.to_node_enumeration.to_a }

          it 'returns hydrated CypherNode objects' do
            expect(node_enumeration[0][:person]).to be_a Neo4j::Server::CypherNode
            expect(node_enumeration[1][:person]).to be_a Neo4j::Server::CypherNode

            expect(node_enumeration[0][:person].neo_id).to eq(18)
            expect(node_enumeration[1][:person].neo_id).to eq(19)

            expect(node_enumeration[0][:person].props).to eq(name: 'Billy', age: 20)
            expect(node_enumeration[1][:person].props).to eq(name: 'Jimmy', age: 24)
          end

          context 'with unwrapped? == true' do
            before { response.unwrapped! }

            it 'does not call wrapper' do
              expect_any_instance_of(Neo4j::Server::CypherNode).not_to receive(:wrapper)
              node_enumeration[0]
            end
          end
        end



        it 'returns hydrated CypherRelationship objects' do
          response = CypherResponse.new(nil, nil)
          response.set_data(data:
            [
              [{type: 'LOVES',
                self: 'http://localhost:7474/db/data/relationship/20',
                start: 'http://localhost:7474/db/data/node/18',
                end: 'http://localhost:7474/db/data/node/19',
                data: {intensity: 2}}],
              [{type: 'LOVES',
                self: 'http://localhost:7474/db/data/relationship/21',
                start: 'http://localhost:7474/db/data/node/19',
                end: 'http://localhost:7474/db/data/node/18',
                data: {intensity: 3}}]
            ],
                            columns: ['r'])

          node_enumeration = response.to_node_enumeration.to_a

          expect(node_enumeration[0][:r]).to be_a Neo4j::Server::CypherRelationship
          expect(node_enumeration[1][:r]).to be_a Neo4j::Server::CypherRelationship

          expect(node_enumeration[0][:r].neo_id).to eq(20)
          expect(node_enumeration[1][:r].neo_id).to eq(21)

          expect(node_enumeration[0][:r].rel_type).to eq(:LOVES)
          expect(node_enumeration[1][:r].rel_type).to eq(:LOVES)

          expect(node_enumeration[0][:r].start_node_neo_id).to eq(18)
          expect(node_enumeration[0][:r].end_node_neo_id).to eq(19)
          expect(node_enumeration[1][:r].start_node_neo_id).to eq(19)
          expect(node_enumeration[1][:r].end_node_neo_id).to eq(18)

          expect(node_enumeration[0][:r].props).to eq(intensity: 2)
          expect(node_enumeration[1][:r].props).to eq(intensity: 3)
        end

        skip 'returns hydrated CypherPath objects?'
      end

      describe 'retryable_error?' do
        let(:response) { Neo4j::Server::CypherResponse.new('', 'query') }

        before do
          response.instance_variable_set(:@error, true)
          response.instance_variable_set(:@error_status, error_status)
          response.instance_variable_set(:@error, true)
        end

        subject { response.retryable_error? }

        context 'deadlock' do
          let(:error_status) { 'DeadlockDetectedException' }
          it { is_expected.to be_truthy }
        end

        context 'acquire lock' do
          let(:error_status) { 'AcquireLockTimeoutException' }
          it { is_expected.to be_truthy }
        end

        context 'external resource' do
          let(:error_status) { 'ExternalResourceFailureException' }
          it { is_expected.to be_truthy }
        end

        context 'unknown failure' do
          let(:error_status) { 'UnknownFailureException' }
          it { is_expected.to be_truthy }
        end
      end

      describe 'CypherResponse::ConstraintViolationError' do
        it 'inherits from ResponseError' do
          expect(CypherResponse::ConstraintViolationError.new(nil, nil, nil)).to be_a(CypherResponse::ResponseError)
        end
      end
    end
  end
end
