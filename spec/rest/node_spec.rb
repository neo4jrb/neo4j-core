require "spec_helper"
require "shared_examples/node"

module Neo4j
  describe Node::Rest, api: :rest do
    include_examples "Node" do
      let (:another_session) { Session.new :rest }
    end
  end
end
