require '../spec_helper'

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
    #after(:each) { Neo4j.threadlocal_ref_node = nil }

    it "#ref_node returns the reference node" do
      @mock_db.should_receive(:reference_node).and_return(MockNode.new)
      Neo4j.ref_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
    end

    it "should be able to change the reference node" do
      new_ref = MockNode.new
      Neo4j.threadlocal_ref_node = new_ref
      Neo4j.ref_node.should == new_ref
    end
  end
  #
  #
  #it "#all_nodes returns a Enumerable of all nodes in the graph database " do
  #  # given created three nodes in a clean database
  #  created_nodes = 3.times.map { Neo4j::Node.new.id }
  #
  #  # when
  #  found_nodes   = Neo4j.all_nodes.map { |node| node.id }
  #
  #  # then
  #  found_nodes.should include(*created_nodes)
  #  found_nodes.should include(Neo4j.ref_node.id)
  #end
  #
  #it "#management returns by default a management for Primitives", :edition => :advanced do
  #  Neo4j.management.get_number_of_node_ids_in_use.should > 0
  #end
end
