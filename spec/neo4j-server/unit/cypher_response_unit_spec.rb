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
            'columns' => ['n'],
            'data' => [[{'labels' => 'http://localhost:7474/db/data/node/625/labels',
                         'outgoing_relationships' => 'http://localhost:7474/db/data/node/625/relationships/out',
                         'data' => {'name' => 'Brian', 'hat' => 'fancy'},
                         'traverse' => 'http://localhost:7474/db/data/node/625/traverse/{returnType}',
                         'all_typed_relationships' => 'http://localhost:7474/db/data/node/625/relationships/all/{-list|&|types}',
                         'property' => 'http://localhost:7474/db/data/node/625/properties/{key}',
                         'self' => 'http://localhost:7474/db/data/node/625',
                         'properties' => 'http://localhost:7474/db/data/node/625/properties',
                         'outgoing_typed_relationships' => 'http://localhost:7474/db/data/node/625/relationships/out/{-list|&|types}',
                         'incoming_relationships' => 'http://localhost:7474/db/data/node/625/relationships/in',
                         'extensions' => {},
                         'create_relationship' => 'http://localhost:7474/db/data/node/625/relationships',
                         'paged_traverse' => 'http://localhost:7474/db/data/node/625/paged/traverse/{returnType}{?pageSize,leaseTime}',
                         'all_relationships' => 'http://localhost:7474/db/data/node/625/relationships/all',
                         'incoming_typed_relationships' => 'http://localhost:7474/db/data/node/625/relationships/in/{-list|&|types}'}]]
          }
        end


        let(:with_tx_response) do
          {
            'commit' => 'http://localhost:7474/db/data/transaction/153/commit',
            'results' => [
              {'columns' => ['n'],
               'data' => [{'row' => [{'name' => 'Brian', 'hat' => 'fancy'}]}]}
            ],
            'transaction' => {'expires' => 'Fri, 08 Aug 2014 11:38:39 +0000'},
            'errors' => []
          }
        end

        shared_examples 'a hash with data and id' do
          specify { expect(subject['data']).to eq('name' => 'Brian', 'hat' => 'fancy') }
          specify { expect(subject['id']).to eq(625) }
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
          response.set_data([[0]], ['ID(n)'])

          expect(response.to_struct_enumeration.to_a).to eq([hash_to_struct(response, :'ID(n)' => 0)])
        end

        it 'creates an enumerable of hash key multiple values' do
          response = CypherResponse.new(nil, nil)
          response.set_data([['Romana', 126], ['The Doctor', 750]], %w(name age))

          expect(response.to_struct_enumeration.to_a).to eq(
            [hash_to_struct(response, name: 'Romana', age: 126),
             hash_to_struct(response, name: 'The Doctor', age: 750)]
          )
        end
      end

      describe '#to_node_enumeration' do
        it 'returns basic values' do
          response = CypherResponse.new(nil, nil)
          response.set_data([['Billy'], ['Jimmy']], ['person.name'])

          expect(response.to_node_enumeration.to_a).to eq([hash_to_struct(response, :'person.name' => 'Billy'), hash_to_struct(response, :'person.name' => 'Jimmy')])
        end

        it 'returns hydrated CypherNode objects' do
          response = CypherResponse.new(nil, nil)
          response.set_data(
            [
              [{'labels' => 'http://localhost:7474/db/data/node/18/labels',
                'self' => 'http://localhost:7474/db/data/node/18',
                'data' => {name: 'Billy', age: 20}}],
              [{'labels' => 'http://localhost:7474/db/data/node/18/labels',
                'self' => 'http://localhost:7474/db/data/node/19',
                'data' => {name: 'Jimmy', age: 24}}]
            ],
            ['person'])

          node_enumeration = response.to_node_enumeration.to_a

          expect(node_enumeration[0][:person]).to be_a Neo4j::Server::CypherNode
          expect(node_enumeration[1][:person]).to be_a Neo4j::Server::CypherNode

          expect(node_enumeration[0][:person].neo_id).to eq(18)
          expect(node_enumeration[1][:person].neo_id).to eq(19)

          expect(node_enumeration[0][:person].props).to eq(name: 'Billy', age: 20)
          expect(node_enumeration[1][:person].props).to eq(name: 'Jimmy', age: 24)
        end

        it 'returns hydrated CypherRelationship objects' do
          response = CypherResponse.new(nil, nil)
          response.set_data(
            [
              [{'type' => 'LOVES',
                'self' => 'http://localhost:7474/db/data/relationship/20',
                'start' => 'http://localhost:7474/db/data/node/18',
                'end' => 'http://localhost:7474/db/data/node/19',
                'data' => {intensity: 2}}],
              [{'type' => 'LOVES',
                'self' => 'http://localhost:7474/db/data/relationship/21',
                'start' => 'http://localhost:7474/db/data/node/19',
                'end' => 'http://localhost:7474/db/data/node/18',
                'data' => {intensity: 3}}]
            ],
            ['r'])

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

        describe '#errors' do
          let(:cypher_response) { CypherResponse.new(response, true) }

          context 'without transaction' do
            let(:response) do
              double('tx_response', status: 400, body: {'message' => 'Some error', 'exception' => 'SomeError', 'fullname' => 'SomeError'})
            end

            it 'returns an array of errors' do
              expect(cypher_response.errors).to be_a(Array)
            end
          end

          context 'using transaction' do
            let(:response) do
              double('non-tx_response', status: 200, body: {'errors' => ['message' => 'Some error', 'status' => 'SomeError', 'code' => 'SomeError'], 'commit' => 'commit_uri'})
            end

            it 'returns an array of errors' do
              expect(cypher_response.errors).to be_a(Array)
            end
          end
        end
      end
    end
  end
end
