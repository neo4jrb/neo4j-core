require "spec_helper"
require "shared_examples/relationship"
require "helpers"

module Neo4j
  describe Java::OrgNeo4jKernelImplCore::RelationshipProxy, api: :embedded do
    include_examples "Relationship"
  end
end
