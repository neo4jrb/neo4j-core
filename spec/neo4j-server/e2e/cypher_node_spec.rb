require 'spec_helper'

describe Neo4j::Server::CypherNode do

  before(:all) do
    @db = Neo4j::Server::CypherDatabase.new("http://localhost:7474/db/data")
  end

  after(:all) do
    @db.unregister
  end

  # it_behaves_like "Neo4j::Node" soon

  describe "class methods" do

    describe "new" do
      it "creates a new node with a neo_id" do
        node = Neo4j::Node.new
        node.neo_id.should be_a(Fixnum)
      end
    end

  end

  describe "instance methods" do
    let(:node) do
      Neo4j::Node.new
    end

    describe '[] and []=' do
      it 'sets a property' do
        node['name'] = 'andreas'
        node['name'].should == 'andreas'
      end
    end
  end
end