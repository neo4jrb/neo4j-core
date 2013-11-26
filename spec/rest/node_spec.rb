require "spec_helper"
require "shared_examples/node"
require "neo4j-core/node/rest"

module Neo4j
  describe Node::Rest, api: :rest do
    include_examples "Node"
  end
end
