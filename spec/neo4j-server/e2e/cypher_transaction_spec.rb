require 'spec_helper'

module Neo4j
  module Server
    describe CypherTransaction, api: :server do
      before { session || create_server_session }

      after do
        session && session.close
        Neo4j::Transaction.current && Neo4j::Transaction.current.close
      end

      context 'where no queries are made' do
        it 'can open and close a transaction' do
          tx = session.begin_tx
          expect { tx.close }.not_to raise_error
        end

        it 'returns an OpenStruct to mimic a completed transaction' do
          tx = session.begin_tx
          response = tx.close
          expect(response.status).to eq(200)
          expect(response).to be_a(OpenStruct)
        end
      end

      context 'where queries are made' do
        it 'can open and close a transaction' do
          tx = session.begin_tx
          tx._query("CREATE (n:Student { name: 'John' } RETURN n")
          response = tx.close
          expect(response.status).to eq 200
          expect(response).to be_a(Faraday::Response)
        end

        it 'can run a valid query' do
          id = session.query.create('(n)').return('ID(n) AS id').first[:id]
          tx = session.begin_tx
          q = tx._query("MATCH (n) WHERE ID(n) = #{id} RETURN ID(n)")
          expect(q.response.body[:results]).to eq([{columns: ['ID(n)'], data: [{row: [id], rest: [id]}]}])
        end

        it 'sets the response error fields if not a valid query' do
          tx = session.begin_tx
          r = tx._query('START n=fs(0) RRETURN ID(n)')
          expect(r.error?).to be true

          expect(r.error_msg).to match(/Invalid input/)
          expect(r.error_status).to match(/Syntax/)
        end

        it 'can rollback' do
          node = Neo4j::Node.create(name: 'andreas')
          Neo4j::Transaction.run do |tx|
            node[:name] = 'foo'
            expect(node[:name]).to eq('foo')
            tx.mark_failed
          end

          expect(node['name']).to eq('andreas')
        end

        it 'can continue operations after transaction is rolled back' do
          node = Neo4j::Node.create(name: 'andreas')
          Neo4j::Transaction.run do |tx|
            tx.mark_failed
            node[:name] = 'foo'
            expect(node[:name]).to eq('foo')
          end
          expect(node['name']).to eq('andreas')
        end

        it 'cannot continue operations if a transaction is expired' do
          node = Neo4j::Node.create(name: 'andreas')
          Neo4j::Transaction.run do |tx|
            tx.mark_expired
            expect { node[:name] = 'foo' }.to raise_error 'Transaction expired, unable to perform query'
          end
        end

        it 'can use Transaction block style' do
          node = Neo4j::Transaction.run { Neo4j::Node.create(name: 'andreas') }
          expect(node[:name]).to eq('andreas')
        end
      end

      describe Neo4j::Label do
        describe '.find_nodes' do
          it 'find and can load them' do
            begin
              tx = Neo4j::Transaction.new
              label_name = unique_random_number.to_s
              n = Neo4j::Node.create({name: 'andreas'}, label_name)
              found = Neo4j::Label.find_nodes(label_name, :name, 'andreas').to_a.first
              expect(found[:name]).to eq('andreas')
              expect(found).to eq(n)
            ensure
              tx.close
            end
          end
        end
      end

      describe Neo4j::Node do
        describe '.load' do
          it 'can load existing node' do
            begin
              node = Neo4j::Node.create(name: 'andreas')
              id = node.neo_id
              tx = Neo4j::Transaction.new
              found = Neo4j::Node.load(id)
              expect(node).to eq(found)
            ensure
              tx.close
            end
          end

          it 'can load node created in tx' do
            begin
              tx = Neo4j::Transaction.new
              node = Neo4j::Node.create(name: 'andreas')
              id = node.neo_id
              found = Neo4j::Node.load(id)
              expect(node).to eq(found)
            ensure
              tx.close
            end
          end
        end
      end

      describe '#create_rel' do
        it 'can create and load it' do
          begin
            tx = Neo4j::Transaction.new
            a = Neo4j::Node.create(name: 'a')
            b = Neo4j::Node.create(name: 'b')
            rel = a.create_rel(:knows, b, colour: 'blue')
            loaded = Neo4j::Relationship.load(rel.neo_id)
            expect(loaded).to eq(rel)
            expect(loaded['colour']).to eq('blue')
          ensure
            tx.close
          end
        end
      end


      describe '#rel' do
        it 'can load it' do
          begin
            tx = Neo4j::Transaction.new
            a = Neo4j::Node.create(name: 'a')
            b = Neo4j::Node.create(name: 'b')
            rel = a.create_rel(:knows, b, colour: 'blue')
            loaded = a.rel(dir: :outgoing, type: :knows)
            expect(loaded).to eq(rel)
            expect(loaded['colour']).to eq('blue')
          ensure
            tx.close
          end
        end
      end

      describe '.create' do
        it 'creates a node' do
          tx = session.begin_tx
          node = Neo4j::Node.create(name: 'andreas')
          expect(tx.close.status).to eq(200)
          expect(node['name']).to eq('andreas')
          # tx.close
        end
      end

      describe '#del' do
        it 'deletes a node' do
          begin
            tx = session.begin_tx
            node = Neo4j::Node.create(name: 'andreas')
            id = node.neo_id
            node.del
          ensure
            tx.close
            loaded = Neo4j::Node.load(id)
            expect(loaded).to be_nil
          end
        end
      end

      describe '#[]=' do
        it 'can update/read a property' do
          node = Neo4j::Node.create(name: 'foo')
          Neo4j::Transaction.run do
            node[:name] = 'bar'
            expect(node[:name]).to eq('bar')
          end
          expect(node[:name]).to eq('bar')
        end
      end
    end
  end
end
