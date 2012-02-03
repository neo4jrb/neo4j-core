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

    describe "#reference_node" do

      it "returns a node (Java::OrgNeo4jGraphdb::Node)" do
        subject.reference_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
      end

    end

    describe "create_node" do
      before(:all) do

      end
      context "without transaction" do
        it "throws TransactionFailureException" do
          lambda do
            subject.create_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
          end.should raise_error(NativeException) # Java::OrgNeo4jGraphdb::TransactionFailureException)
        end
      end

      context "with transaction" do
        before { @tx = subject.begin_tx }
        after do
          begin
            @tx.success; @tx.finish
          end if @tx
        end

        it "returns a Java::OrgNeo4jGraphdb::Node" do
          subject.create_node.should be_kind_of(Java::OrgNeo4jGraphdb::Node)
        end
      end

    end
  end

end

