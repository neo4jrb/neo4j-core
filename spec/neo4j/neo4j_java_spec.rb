require '../spec_helper'

describe Java::OrgNeo4jKernel::EmbeddedGraphDatabase, :type => :java_integration do


  describe "#new" do
    it "can be created with a Neo4j::Config properties " do
      File.exist?(Neo4j::Config[:storage_path]).should be_false
      db = Java::OrgNeo4jKernel::EmbeddedGraphDatabase.new(Neo4j::Config[:storage_path], Neo4j.config.to_java_map)  #(Neo4j::Config[:storage_path]) #, Neo4j.config.to_java_map)
      File.exist?(Neo4j::Config[:storage_path]).should be_true
      db.shutdown
    end
  end

end
