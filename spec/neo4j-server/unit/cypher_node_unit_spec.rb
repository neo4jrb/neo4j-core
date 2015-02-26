require 'spec_helper'

module Neo4j
  module Server
    describe CypherNode do
      let(:session) do
        allow_any_instance_of(CypherSession).to receive(:initialize_resource)
        CypherSession.new('http://an.url', connection)
      end

      let(:connection) do
        double('connection')
      end

      let(:match_string) { 'MATCH (n) WHERE ID(n) = {neo_id}' }

      describe 'instance methods' do
        describe 'props' do
          let(:cypher_body) do
            JSON.parse <<-HERE
          {
            "columns" : [ "a" ],
            "data" : [ [ {
              "outgoing_relationships" : "http://localhost:7474/db/data/node/43/relationships/out",
              "labels" : "http://localhost:7474/db/data/node/43/labels",
              "data" : {
                "name" : "andreas"
              },
              "all_typed_relationships" : "http://localhost:7474/db/data/node/43/relationships/all/{-list|&|types}",
              "traverse" : "http://localhost:7474/db/data/node/43/traverse/{returnType}",
              "self" : "http://localhost:7474/db/data/node/43",
              "property" : "http://localhost:7474/db/data/node/43/properties/{key}",
              "outgoing_typed_relationships" : "http://localhost:7474/db/data/node/43/relationships/out/{-list|&|types}",
              "properties" : "http://localhost:7474/db/data/node/43/properties",
              "incoming_relationships" : "http://localhost:7474/db/data/node/43/relationships/in",
              "extensions" : {
              },
              "create_relationship" : "http://localhost:7474/db/data/node/43/relationships",
              "paged_traverse" : "http://localhost:7474/db/data/node/43/paged/traverse/{returnType}{?pageSize,leaseTime}",
              "all_relationships" : "http://localhost:7474/db/data/node/43/relationships/all",
              "incoming_typed_relationships" : "http://localhost:7474/db/data/node/43/relationships/in/{-list|&|types}"
            } ] ]
          }
            HERE
          end

          let(:cypher_response) do
            double('cypher response', error?: false, first_data: cypher_body[:data][0][0])
          end

          it 'returns all properties' do
            node = CypherNode.new(session, 42)
            expect(session).to receive(:_query_entity_data).with("#{match_string} RETURN n", nil, neo_id: 42).and_return(data: {name: 'andreas'})
            expect(node.props).to eq(name: 'andreas')
          end
        end

        describe 'exist?' do
          it 'generates correct cypher' do
            cypher_response = double('cypher response', error?: false)
            expect(session).to receive(:_query).with("#{match_string} RETURN ID(n)", neo_id: 42).and_return(cypher_response)
            node = CypherNode.new(session, 42)
            node.init_resource_data({}, 'http://bla/42')
            expect(cypher_response).to receive(:data).and_return([])
            # when
            node.exist?
          end

          it 'returns true if response contains node data' do
            node = CypherNode.new(session, 42)
            node.init_resource_data({}, 'http://bla/42')
            response = double('response', error?: false)
            expect(session).to receive(:_query).and_return(response)
            expect(response).to receive(:data).and_return([:foo])

            expect(node.exist?).to be true
          end
        end

        describe '[]=' do
          it 'generates correct cypher' do
            node = CypherNode.new(session, 42)
            response = double('cypher response', error?: false)
            expect(session).to receive(:_query).with("#{match_string} SET n.`name` = { value }",  value: 'andreas', neo_id: node.neo_id).and_return(response)
            node['name'] = 'andreas'
          end

          it 'removed property if setting it to a nil value' do
            node = CypherNode.new(session, 42)
            response = double('cypher response', error?: false)
            expect(session).to receive(:_query).with("#{match_string} REMOVE n.`name`", neo_id: 42).and_return(response)
            node['name'] = nil
          end
        end

        describe '[]' do
          it 'generates correct cypher' do
            node = CypherNode.new(session, 42)
            response = double('cypher response', first_data: 'andreas', error?: false)
            expect(session).to receive(:_query).with("#{match_string} RETURN n.`name`", neo_id: 42).and_return(response)
            expect(node['name']).to eq('andreas')
          end
        end
      end
    end
  end
end
