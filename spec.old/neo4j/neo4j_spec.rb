require 'spec_helper'

describe Neo4j do

  context "not running", :type => :mock_db do

    describe "#start" do
      before(:each) do
        Neo4j.shutdown
      end

      it "is running" do
        Neo4j.start
        Neo4j.running?.should == true
      end

      it "should call the event handler :neo4j_started" do
        Neo4j.db.event_handler.should_receive(:neo4j_started).with(Neo4j.db)
        Neo4j.start
      end

      it "should not be read only" do
        Neo4j.start
        Neo4j.should_not be_read_only
      end

      context "it is started again" do
        it "should happen nothing" do
          Neo4j.start
          Neo4j.should be_running
          Neo4j.start
          Neo4j.should be_running
        end
      end
    end
  end

  context "when it is running" do
    before(:each) do
      Neo4j.start
      Neo4j.running?.should == true
    end

    describe "#shutdown", :type => :mock_db do
      it "should shutdown the server" do
        Neo4j.shutdown
        Neo4j.should_not be_running
      end

      it "should call the event handler :neo4j_shutdown" do
        Neo4j.db.event_handler.should_receive(:neo4j_shutdown).with(Neo4j.db)
        Neo4j.shutdown
      end
    end
  end


  describe "reference node", :type => :mock_db do
    it "#ref_node returns the reference node" do
      Neo4j.db.graph.should_receive(:reference_node).and_return(MockNode.new)
      Neo4j.ref_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
    end

    it "should be able to change the reference node" do
      new_ref = MockNode.new
      Neo4j.threadlocal_ref_node = new_ref
      Neo4j.ref_node.should == new_ref
    end
  end

  describe "start with external database" do
    after do
      Neo4j.shutdown
    end

    it "uses the specified Neo4j database instance" do
      my_db = MockDb.new
      Neo4j.start(nil, my_db)
      Neo4j.db.graph.should == my_db
    end

  end
end
