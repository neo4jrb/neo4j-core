require 'spec_helper'

describe Neo4j, :type => :integration do

  describe "all_nodes" do
    it "returns an enumerable" do
      Neo4j.all_nodes.should be_kind_of(Enumerable)
    end
  end

  describe "managements" do
    it "returns by default a management for Primitives", :edition => :advanced do
      Neo4j.management.get_number_of_node_ids_in_use.should > 0
    end
  end
end