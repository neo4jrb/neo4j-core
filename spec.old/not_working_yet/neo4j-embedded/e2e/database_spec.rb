require 'spec_helper'

include Neo4j
describe Neo4j::Database do

  before(:all) do
    # TODO use ImpermanentDatabase
    @db = Neo4j::Embedded::Database.new('path', delete_existing_db: true, auto_commit: true)
  end

  after(:all) do
    @db.shutdown
  end

  it "can create a new and find it" do
    red = Neo4j::Label.create(:red)
    red.index(:name)
    Neo4j::Node.create({name: 'andreas'}, red, :green)
    red.find_nodes(:name, "andreas").map{|node| node[:name]}.should == ['andreas']
  end

  it "can use raw java api not wrapped" do
    tx = @db.begin_tx
    red = Neo4j::Label.create(:yellow)
    red.index(:name)
    Neo4j::Node.create({name: 'jimmy'}, :yellow)
    iterator = red._find_nodes(:name, "jimmy")
    iterator.to_a.map{|n| n[:name]}.should == ['jimmy']
    iterator.close  # Don't forget !
    tx.success
    tx.finish
  end
end
