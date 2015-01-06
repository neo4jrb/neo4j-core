# require 'spec_helper'
# require 'ostruct'

# describe Neo4j::Server::CypherTransaction do
#   let(:body) { {'commit' => 'commit url'} }
#   let(:response) { OpenStruct.new(headers: {'Location' => 'tx url'}, body: body, status: 201) }
#   let(:connection) { double('A Faraday::Connection object') }
#   let(:a_new_transaction) { Neo4j::Server::CypherTransaction.new('some url', connection) }

#   after(:each) { Thread.current[:neo4j_curr_tx] = nil }

#   describe 'initialize' do
#     it 'creates a Transaction shell without an exec_url' do
#       expect(a_new_transaction.exec_url).to be_nil
#     end

#     it 'sets the base_url' do
#       expect(a_new_transaction.base_url).to eq('some url')
#     end
#   end

#   describe '_query' do
#     it 'sets the exec_url, commit_url during its first query and leaves the transaction open' do
#       expect(a_new_transaction.exec_url).to be_nil
#       expect(a_new_transaction.commit_url).to be_nil
#       expect(connection).to receive(:post).with('some url', anything).and_return(response)
#       expect(a_new_transaction).to receive(:_create_cypher_response).with(response)
#       a_new_transaction._query('MATCH (n) WHERE ID(n) = 42 RETURN n')
#       expect(a_new_transaction.exec_url).not_to be_nil
#       expect(a_new_transaction.commit_url).not_to be_nil
#     end

#     it 'posts to the exec url once set' do
#       expect(connection).to receive(:post).with('some url', anything).and_return(response)
#       # expect(connection).
#       a_new_transaction._query("MATCH (n) WHERE ID(n) = 42 SET n.name = 'Bob' RETURN n")
#     end
#   end

#   describe 'close' do
#     it 'post to the commit url' do
#       expect(connection).to receive(:post).with('commit url').and_return(OpenStruct.new(status: 200))
#       a_new_transaction.close
#     end

#     it 'commits and unregisters the transaction' do
#       expect(Neo4j::Transaction).to receive(:unregister)
#       expect(a_new_transaction).to receive(:_commit_tx)
#       a_new_transaction.close
#     end

#     it 'raise an exception if it is already commited' do
#       expect(connection).to receive(:post).with('commit url').and_return(OpenStruct.new(status: 200))
#       a_new_transaction.close

#       # bang
#       expect { a_new_transaction.close }.to raise_error(/already committed/)
#     end
#   end

#   describe 'push_nested!' do
#     it 'will not close a transaction if transaction is nested' do
#       a_new_transaction.push_nested!
#       expect(Neo4j::Transaction).to_not receive(:unregister)
#       a_new_transaction.close
#     end
#   end

#   describe 'pop_nested!' do
#     it 'commits and unregisters the transaction if poped after pushed' do
#       a_new_transaction.push_nested!
#       a_new_transaction.pop_nested!
#       expect(Neo4j::Transaction).to receive(:unregister)
#       expect(a_new_transaction).to receive(:_commit_tx)
#       a_new_transaction.close
#     end

#     it 'does not commit if pushed more then popped' do
#       a_new_transaction.push_nested!
#       a_new_transaction.push_nested!
#       a_new_transaction.pop_nested!
#       expect(Neo4j::Transaction).to_not receive(:unregister)
#       a_new_transaction.close
#     end

#     it 'needs to pop one for each pushed in order to close tx' do
#       a_new_transaction.push_nested!
#       a_new_transaction.push_nested!
#       a_new_transaction.pop_nested!
#       a_new_transaction.pop_nested!
#       expect(Neo4j::Transaction).to receive(:unregister)
#       expect(a_new_transaction).to receive(:_commit_tx)
#       a_new_transaction.close
#     end
#   end
# end
