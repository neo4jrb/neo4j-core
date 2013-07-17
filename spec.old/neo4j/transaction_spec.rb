require 'spec_helper'

describe Neo4j::Transaction, :type => :mock_db do

  describe "new" do
    it "starts a new transaction using the default started db" do
      Neo4j.db.graph.should_receive(:begin_tx).and_return(42)
      Neo4j::Transaction.new.should == 42
    end

    it "can starts a new transaction using a different db" do
      other_db = mock("other db")
      other_db.should_receive(:begin_tx).and_return(42)
      Neo4j::Transaction.new(other_db).should == 42
    end
  end

  describe "run" do
    it "calls success and finish if the block does not raise an exception" do
      mock_tx = mock("tx")
      mock_tx.should_receive(:success)
      mock_tx.should_receive(:finish)
      Neo4j.db.graph.should_receive(:begin_tx).and_return(mock_tx)
      Neo4j::Transaction.run { 123 }.should == 123
    end

    it "calls failure and finish if the block DOES raise an exception" do
      mock_tx = mock("tx")
      mock_tx.should_receive(:failure)
      mock_tx.should_receive(:finish)
      Neo4j.db.graph.should_receive(:begin_tx).and_return(mock_tx)
      lambda { Neo4j::Transaction.run { raise "oops" } }.should raise_error
    end


  end
end