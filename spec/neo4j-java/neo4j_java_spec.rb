require 'spec_helper'

describe Java::OrgNeo4jKernel::EmbeddedGraphDatabase, :type => :java_integration do


  context "A running db" do
    context "without transaction" do
      describe "#reference_node" do
        it "returns a node (Java::OrgNeo4jGraphdb::Node)" do
          embedded_db.reference_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
        end

      end

      describe "#get_node_by_id" do
        it "throws Java::OrgNeo4jGraphdb.NotFoundException if node does not exist" do
          lambda {embedded_db.get_node_by_id(4242)}.should raise_error(Java::OrgNeo4jGraphdb.NotFoundException)
        end

        it "returns the node if it exists" do
          found = embedded_db.get_node_by_id(embedded_db.reference_node.neo_id)
          found.getId.should == embedded_db.reference_node.neo_id
        end

      end

      describe "#create_node" do
        it "throws TransactionFailureException" do
          lambda do
            embedded_db.create_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
          end.should raise_error(NativeException) # Java::OrgNeo4jGraphdb::TransactionFailureException)
        end
      end
    end

    context "with transaction" do
      before { new_java_tx(embedded_db)}
      after { finish_tx}

      describe "#create_node" do
        it "returns a Java::OrgNeo4jGraphdb::Node" do
          embedded_db.create_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
        end

        it "can be found before transaction commits" do
          new_node = embedded_db.create_node

          found = embedded_db.get_node_by_id(new_node.get_id)
          found.get_id.should == new_node.get_id
        end

        it "can be found after transaction commits" do
          new_node = embedded_db.create_node
          @tx.success; @tx.finish; @tx = nil
          found = embedded_db.get_node_by_id(new_node.get_id)
          found.get_id.should == new_node.get_id
        end

      end
    end

  end

end

