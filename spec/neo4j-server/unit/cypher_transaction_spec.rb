# require 'spec_helper'
# require 'ostruct'
#
# describe Neo4j::Server::CypherTransaction do
#
#   let(:body) do
#     {'commit' => 'commit url'}
#   end
#
#   let(:expired_tx_body) do
#     {'errors' => ['message' => 'Unknown id', 'status' => 'UnknownId', 'code' => 'Neo.ClientError.Transaction.UnknownId'], 'commit' => 'commit_uri'}
#   end
#
#   let(:failed_tx_body) do
#     {'errors' => ['message' => 'Unknown failure', 'status' => 'UnknownFailure', 'code' => 'Neo.DatabaseError.General.UnknownFailure'], 'commit' => 'commit_uri'}
#   end
#
#   let(:expired_transaction) { Neo4j::Server::ExpiredCypherTransaction.new(nil) }
#   let(:failed_transaction)  { Neo4j::Server::FailedCypherTransaction.new(nil) }
#
#   let(:response) do
#     OpenStruct.new(headers: {'Location' => 'tx url'}, body: body, status: 201)
#   end
#
#   let(:endpoint) do
#     double(:endpoint)
#   end
#
#   let(:a_new_transaction) do
#     Neo4j::Server::CypherTransaction.new(nil,response, 'some url', endpoint)
#   end
#
#   after(:each) do
#     Thread.current[:neo4j_curr_tx] = nil
#     #Neo4j::Transaction.unregister(Neo4j::Transaction.current) if Neo4j::Transaction.current
#   end
#
#   describe 'initialize' do
#
#     it 'sets exec_url' do
#       expect(a_new_transaction.exec_url).to eq('tx url')
#     end
#
#   end
#
#   describe '_query' do
#     context 'with valid transaction' do
#       let(:body) do
#         {'results' => [{'columns' => ['id(n)'], 'data' => [{'row' => [3]}]}], 'errors' => [], 'commit' => 'commit_uri'}
#       end
#
#       it 'post a query to the exec_url' do
#         expect(endpoint).to receive(:post).with('tx url', anything).and_return(response)
#         a_new_transaction._query('START n=node(42) RETURN n')
#       end
#     end
#
#     context 'with expired transaction' do
#       let(:body) { expired_tx_body }
#
#       it 'sets current transaction to expired' do
#         expect(endpoint).to receive(:post).with('tx url', anything).and_return(response)
#         a_new_transaction._query('START n=node(42) RETURN n')
#         expect(Neo4j::Transaction.current).to be_a(Neo4j::Server::ExpiredCypherTransaction)
#       end
#
#       it 'does not post to the database' do
#         expect_any_instance_of(Faraday::Connection).not_to receive(:post)
#         expired_transaction._query('START n=node(42) RETURN n')
#       end
#     end
#
#     context 'with failed transaction' do
#       let(:body) { failed_tx_body }
#
#       it 'sets current transaction to failed' do
#         expect(endpoint).to receive(:post).with('tx url', anything).and_return(response)
#         a_new_transaction._query('START n=node(42) RETURN n')
#         expect(Neo4j::Transaction.current).to be_a(Neo4j::Server::FailedCypherTransaction)
#       end
#
#       it 'does not post to the database' do
#         expect_any_instance_of(Faraday::Connection).not_to receive(:post)
#         failed_transaction._query('START n=node(42) RETURN n')
#       end
#     end
#   end
#
#   describe 'close' do
#     context 'with valid transaction' do
#       it 'post to the commit url' do
#         expect(endpoint).to receive(:post).with('commit url').and_return(OpenStruct.new(status: 200))
#         a_new_transaction.close
#       end
#
#       it 'commits and unregisters the transaction' do
#         expect(Neo4j::Transaction).to receive(:unregister)
#         expect(a_new_transaction).to receive(:_commit_tx)
#         a_new_transaction.close
#       end
#
#       it 'raise an exception if it is already commited' do
#         expect(endpoint).to receive(:post).with('commit url').and_return(OpenStruct.new(status: 200))
#         a_new_transaction.close
#
#         # bang
#         expect{a_new_transaction.close}.to raise_error(/already committed/)
#       end
#     end
#
#     context 'with expired transaction' do
#       let(:body) { expired_tx_body }
#
#       it 'does not post to the database' do
#         expect_any_instance_of(Faraday::Connection).not_to receive(:post)
#         expired_transaction.close
#       end
#     end
#
#     context 'with failed transaction' do
#       let(:body) { failed_tx_body }
#
#       it 'does not post to the database' do
#         expect_any_instance_of(Faraday::Connection).not_to receive(:post)
#         failed_transaction.close
#       end
#     end
#   end
#
#   describe 'push_nested!' do
#
#     it 'will not close a transaction if transaction is nested' do
#       a_new_transaction.push_nested!
#       expect(Neo4j::Transaction).to_not receive(:unregister)
#       a_new_transaction.close
#     end
#
#   end
#
#   describe 'pop_nested!' do
#     it 'commits and unregisters the transaction if poped after pushed' do
#       a_new_transaction.push_nested!
#       a_new_transaction.pop_nested!
#       expect(Neo4j::Transaction).to receive(:unregister)
#       expect(a_new_transaction).to receive(:_commit_tx)
#       a_new_transaction.close
#     end
#
#     it 'does not commit if pushed more then popped' do
#       a_new_transaction.push_nested!
#       a_new_transaction.push_nested!
#       a_new_transaction.pop_nested!
#       expect(Neo4j::Transaction).to_not receive(:unregister)
#       a_new_transaction.close
#     end
#
#     it 'needs to pop one for each pushed in order to close tx' do
#       a_new_transaction.push_nested!
#       a_new_transaction.push_nested!
#       a_new_transaction.pop_nested!
#       a_new_transaction.pop_nested!
#       expect(Neo4j::Transaction).to receive(:unregister)
#       expect(a_new_transaction).to receive(:_commit_tx)
#       a_new_transaction.close
#     end
#
#   end
# end