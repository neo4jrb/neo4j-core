require "spec_helper"
require "shared_examples/relationship"

module Neo4j
  describe Relationship::Rest, api: :rest do
    include_examples "Relationship"
  end
end
