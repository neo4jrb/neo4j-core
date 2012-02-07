require '../spec_helper'

describe Java::OrgNeo4jKernel::EmbeddedGraphDatabase, :type => :java_integration do


  describe "#new" do
    it "can be created with a Neo4j::Config properties " do
      File.exist?(Neo4j::Config[:storage_path]).should be_false
      db = Java::OrgNeo4jKernel::EmbeddedGraphDatabase.new(Neo4j::Config[:storage_path], Neo4j.config.to_java_map) #(Neo4j::Config[:storage_path]) #, Neo4j.config.to_java_map)
      File.exist?(Neo4j::Config[:storage_path]).should be_true
      db.shutdown
    end
  end

  context "A running db" do
    subject do
      @@db ||=Java::OrgNeo4jKernel::EmbeddedGraphDatabase.new(Neo4j::Config[:storage_path], Neo4j.config.to_java_map) #(Neo4j::Config[:storage_path]) #, Neo4j.config.to_java_map)
    end

    after(:all) do
      subject.shutdown
    end

    context "without transaction" do

      describe "#reference_node" do
        it "returns a node (Java::OrgNeo4jGraphdb::Node)" do
          subject.reference_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
        end

      end

      describe "#get_node_by_id" do
        it "throws Java::OrgNeo4jGraphdb.NotFoundException if node does not exist" do
          lambda {subject.get_node_by_id(4242)}.should raise_error(Java::OrgNeo4jGraphdb.NotFoundException)
        end

        it "throws Java::OrgNeo4jGraphdb.NotFoundException if node does not exist" do
          found = subject.get_node_by_id(subject.reference_node.neo_id)
          found.getId.should == subject.reference_node.neo_id
        end

      end

      describe "#create_node" do
        it "throws TransactionFailureException" do
          lambda do
            subject.create_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
          end.should raise_error(NativeException) # Java::OrgNeo4jGraphdb::TransactionFailureException)
        end
      end
    end

    context "with transaction" do
      before { @tx = subject.begin_tx }
      after do
        begin
          @tx.success; @tx.finish
        end if @tx
      end

      describe "#create_node" do
        it "returns a Java::OrgNeo4jGraphdb::Node" do
          subject.create_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
        end

        it "can be found before transaction commits" do
          new_node = subject.create_node

          found = subject.get_node_by_id(new_node.get_id)
          found.get_id.should == new_node.get_id
        end

        it "can be found after transaction commits" do
          new_node = subject.create_node
          @tx.success; @tx.finish; @tx = nil
          found = subject.get_node_by_id(new_node.get_id)
          found.get_id.should == new_node.get_id
        end

      end


    end

  end

end

