require '../spec_helper'

describe Java::OrgNeo4jGraphdb::Node, :type => :java_integration do

  let!(:db) do
    @db ||= Java::OrgNeo4jKernel::EmbeddedGraphDatabase.new(Neo4j::Config[:storage_path], Neo4j.config.to_java_map) #(Neo4j::Config[:storage_path]) #, Neo4j.config.to_java_map)
  end

  after(:all) do
    db.shutdown
    @db = nil
  end

  context "an existing node" do
    before(:all) do
      @tx = db.begin_tx
    end

    after(:all) do
      return unless @tx
      @tx.success; @tx.finish
    end

    let!(:existing_node) do
      db.create_node
    end


    describe "#get_property" do
      it "raise Java::OrgNeo4jGraphdb.NotFoundException if property does not exist" do
        lambda { existing_node.get_property("KALLE") }.should raise_error(Java::OrgNeo4jGraphdb.NotFoundException)
      end

    end

    {'name' => 'andreas', 'age' => 42, 'size' => 3.14, 'enabled' => true, "disabled" => false}.each_pair do |key, value|
      describe "#set_property(#{key}, #{value})" do
        it "should set the value" do
          existing_node.set_property(key, value)
          existing_node.get_property(key).should == value
        end

        it "should have the property" do
          existing_node.should have_property(key)
        end
      end

      describe "remove_property #{key}" do
        it "can delete the property" do
          existing_node.set_property(key, value)
          existing_node.remove_property(key)
          existing_node.should_not have_property(key)
        end

      end
    end

    describe "#set_property with an Array" do
      it "should handle String arrays" do
        value = ['foo', 'bar']
        existing_node.set_property("my_array", value.to_java(:string))
        existing_node.get_property("my_array").to_a.should == value
      end

      it "should handle Fixnum arrays" do
        value = [123, 423]
        existing_node.set_property("my_array", value.to_java(:long))
        existing_node.get_property("my_array").to_a.should == value
      end

      it "should handle Boolean arrays" do
        value = [true, false, true]
        existing_node.set_property("my_array", value.to_java(:boolean))
        existing_node.get_property("my_array").to_a.should == value
      end

      it "should handle Float arrays" do
        value = [4.32, 1.32, 5.31]
        existing_node.set_property("my_array", value.to_java(:double))
        existing_node.get_property("my_array").to_a.should == value
      end

    end


  end


end
