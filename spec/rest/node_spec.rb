require "spec_helper"
require "shared_examples/node"

module Neo4j
  describe Node::Rest, api: :rest do
    include_examples "node"
  end
end
