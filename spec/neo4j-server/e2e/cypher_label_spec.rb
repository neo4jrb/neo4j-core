require 'spec_helper'

describe 'label', api: :server do

  it_behaves_like "Neo4j::Label"


  # This should be moved to Neo4j::Label so we get it for the embedded impl as well.
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