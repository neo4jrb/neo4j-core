require "spec_helper"
require "shared_examples/node"
require "helpers"

module Neo4j
  describe Java::OrgNeo4jKernelImplCore::NodeProxy, api: :embedded do
    include_examples "Node" do
      let (:another_session) do
        another_session = Session.new(:embedded, Helpers::Embedded.test_path)
        another_session.start
        another_session
      end
    end
  end
end
