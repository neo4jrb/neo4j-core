require 'spec_helper'

describe "Neo4j::Embedded::EmbeddedLabel", api: :embedded do

  it_behaves_like "Neo4j::Label"

  # TODO, DRY move this to Neo4j::Label so it can be reused for server_db specs
  describe 'add_labels' do
    it 'can add labels' do
      node = Neo4j::Node.create
      node.add_label(:new_label)
      node.labels.should include(:new_label)
    end

    it 'escapes label names' do
      node = Neo4j::Node.create
      node.add_label(":bla")
      node.labels.should include(:':bla')
    end

    it 'can set several labels in one go' do
      node = Neo4j::Node.create
      node.add_label(:one, :two, :three)
      node.labels.should include(:one, :two, :three)
    end
  end


  describe 'delete_label' do
    it 'delete given label' do
      node = Neo4j::Node.create({}, :one, :two)
      node.delete_label(:two)
      node.labels.should == [:one]
    end

    it 'can delete all labels' do
      node = Neo4j::Node.create({}, :one, :two)
      node.delete_label(:two, :one)
      node.labels.should == []
    end

  end

end