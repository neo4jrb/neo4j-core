require 'spec_helper'

describe Java::OrgNeo4jGraphdb::Node, :type => :java_integration do

  context "an existing node" do

    let(:existing_node) { @existing_node }

    before(:all) do
      new_java_tx(embedded_db)
      @existing_node = embedded_db.create_node
    end

    after(:all) do
      finish_tx
    end

    describe "#get_property" do
      it "raise Java::OrgNeo4jGraphdb.NotFoundException if property does not exist" do
        lambda { existing_node.get_property("KALLE") }.should raise_error(Java::OrgNeo4jGraphdb.NotFoundException)
      end

    end

    describe "#set_property" do

      {'name' => 'andreas', 'age' => 42, 'size' => 3.14, 'enabled' => true, "disabled" => false}.each_pair do |key, value|
        it "should set the value #{key} to #{value.inspect}" do
          existing_node.set_property(key, value)
          existing_node.get_property(key).should == value
        end

        it "should have the property #{key}" do
          existing_node.has_property(key).should be_true #should have_property(key)
                                                         #existing_node.should have_property(key)
        end

        it "can delete the property #{key} with remove_property" do
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

    describe "delete" do

      context "before commit" do
        let(:before_commit_deleted_node) { @before_commit_deleted_node}

        before do
          new_java_tx(embedded_db)
          @before_commit_deleted_node = embedded_db.create_node
          @before_commit_deleted_node.delete
        end

        after { finish_tx }

        describe "get_node_by_id" do
          it "returns the node" do
            embedded_db.get_node_by_id(before_commit_deleted_node.getId).should == before_commit_deleted_node
          end
        end

        describe "get_property" do
          it "raise Java::JavaLang::IllegalStateException" do
            lambda { before_commit_deleted_node.get_property("Foo") }.should raise_error(Java::JavaLang::IllegalStateException)
          end
        end

        describe "set_property" do
          it "raise Java::JavaLang::IllegalStateException and it should not be possible to commit the transaction" do
            lambda { before_commit_deleted_node.set_property("Foo", "Bar") }.should raise_error(Java::JavaLang::IllegalStateException)
            lambda {finish_tx}.should raise_error(Java::OrgNeo4jGraphdb::TransactionFailureException)
          end
        end

      end


      context "after commit" do
        let(:after_commit_deleted_node) do
          new_java_tx(embedded_db)
          node = embedded_db.create_node
          node.delete
          finish_tx
          node
        end

        describe "get_node_by_id" do
          it "raise org.neo4j.graphdb.NotFoundException" do
            lambda { embedded_db.get_node_by_id(after_commit_deleted_node.getId) }.should raise_error(Java::OrgNeo4jGraphdb::NotFoundException)
          end
        end

        describe "get_property" do
          it "raise org.neo4j.graphdb.NotFoundException" do
            lambda { after_commit_deleted_node.get_property("Foo") }.should raise_error(Java::OrgNeo4jGraphdb::NotFoundException)
          end
        end

        describe "set_property" do
          it "raise org.neo4j.graphdb.NotFoundException" do
            lambda { after_commit_deleted_node.set_property("Foo", "Bar") }.should raise_error(Java::OrgNeo4jGraphdb::NotFoundException)
          end
        end

      end
    end


  end


end
