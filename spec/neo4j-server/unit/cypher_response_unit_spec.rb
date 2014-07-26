require 'spec_helper'

module Neo4j::Server
  describe CypherResponse do
    def hash_to_struct(response, hash)
      response.struct.new(*hash.values)
    end

    describe '#to_struct_enumeration' do
      it "creates a enumerable of hash key values" do
          #result.data.should == [[0]]
          #result.columns.should == ['ID(n)']
        response = CypherResponse.new(nil,nil)
        response.set_data([[0]], ['ID(n)'])

        expect(response.to_struct_enumeration.to_a).to eq([hash_to_struct(response, {:'ID(n)' => 0})])
      end

      it "creates an enumerable of hash key multiple values" do
        response = CypherResponse.new(nil,nil)
        response.set_data([['Romana', 126],['The Doctor',750]], ['name', 'age'])

        expect(response.to_struct_enumeration.to_a).to eq(
          [hash_to_struct(response, {:name => 'Romana', :age => 126}),
           hash_to_struct(response, {:name => 'The Doctor', :age => 750})]
        )
      end
    end

    describe '#to_node_enumeration' do
      it 'returns basic values' do
        response = CypherResponse.new(nil,nil)
        response.set_data([['Billy'], ['Jimmy']], ['person.name'])

        expect(response.to_node_enumeration.to_a).to eq([hash_to_struct(response, {:'person.name' => 'Billy'}), hash_to_struct(response, {:'person.name' => 'Jimmy'})])
      end

      it 'returns hydrated CypherNode objects' do
        response = CypherResponse.new(nil,nil)
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

        expect(node_enumeration[0][:person].props).to eq({name: 'Billy', age: 20})
        expect(node_enumeration[1][:person].props).to eq({name: 'Jimmy', age: 24})
      end

      it 'returns hydrated CypherRelationship objects' do
        response = CypherResponse.new(nil,nil)
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

        expect(node_enumeration[0][:r].props).to eq({intensity: 2})
        expect(node_enumeration[1][:r].props).to eq({intensity: 3})
      end

      skip 'returns hydrated CypherPath objects?'
    end
  end

end

