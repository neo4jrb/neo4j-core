require "spec_helper"
require "shared_examples/node"
require "helpers"

module Neo4j
  describe Java::OrgNeo4jKernelImplCore::NodeProxy, api: :embedded do
    include_examples "Node"
  end
end
