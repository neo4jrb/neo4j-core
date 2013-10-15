require 'spec_helper'

describe 'label', api: :embedded do

  it_behaves_like "Neo4j::Label"

end