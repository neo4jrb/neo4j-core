require "spec_helper"

module Neo4j
  describe 'Embedded Node', api: :embedded do
    include_examples "node"
  end
end
