require 'spec_helper'

describe 'Neo4j::Embedded::EmbeddedLabel', api: :embedded do

  it_behaves_like 'Neo4j::Label'

end
