require 'spec_helper'

describe 'label', api: :server, server_only: true do
  it_behaves_like 'Neo4j::Label'
end
