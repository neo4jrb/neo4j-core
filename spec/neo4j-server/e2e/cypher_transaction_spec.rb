require 'spec_helper'

module Neo4j::Server
  describe CypherTransaction, api: :server do

    before do
      session || create_server_session
    end

    after do
      session && session.close
      Neo4j::Transaction.current && Neo4j::Transaction.current.finish
    end


    it "can open and commit a transaction" do
      tx = session.begin_tx
      tx.success
      tx.finish
    end

    it "can run a valid query" do
      id = session.query.create("(n)").return("ID(n) AS id").first[:id]

      tx = session.begin_tx

      q = tx._query("START n=node(#{id}) RETURN ID(n)")
      expect(q.response['results']).to eq([{"columns"=>["ID(n)"], "data"=>[{"row"=>[id]}]}])
    end


    it "sets the response error fields if not a valid query" do
      tx = session.begin_tx
      r = tx._query("START n=fs(0) RRETURN ID(n)")
      expect(r.error?).to be true

      expect(r.error_msg).to match(/Invalid input/)
      expect(r.error_status).to match(/Syntax/)
    end

    it 'can commit' do
      tx = session.begin_tx
      tx.success
      response = tx.finish
      expect(response.code).to eq(200)
    end


    it "can create a node" do
      tx = session.begin_tx
      node = Neo4j::Node.create(name: 'andreas')
      tx.success
      expect(tx.finish.code).to eq(200)
      expect(node['name']).to eq('andreas')
    end


    it "can update a property" do
      node = Neo4j::Node.create(name: 'foo')
      Neo4j::Transaction.run do
        node[:name] = 'bar'
        expect(node[:name]).to eq('bar')
      end
      expect(node[:name]).to eq('bar')
    end

    it 'can rollback' do
      node = Neo4j::Node.create(name: 'andreas')
      Neo4j::Transaction.run do |tx|
        node[:name] = 'foo'
        expect(node[:name]).to eq('foo')
        tx.failure
      end

      expect(node['name']).to eq('andreas')
    end

    it 'can continue operations after transaction is rolled back' do
      node = Neo4j::Node.create(name: 'andreas')
      Neo4j::Transaction.run do |tx|
        tx.failure
        node[:name] = 'foo'
        expect(node[:name]).to eq('foo')
      end
      expect(node['name']).to eq('andreas')

    end

    it "can use Transaction block style" do
      node = Neo4j::Transaction.run do
        Neo4j::Node.create(name: 'andreas')
      end

      expect(node['name']).to eq('andreas')
    end
  end
end
