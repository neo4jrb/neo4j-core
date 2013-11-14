require "spec_helper"
require "shared_examples/session"

module Neo4j
  describe Session::Rest, api: :rest do
    include_examples "Session"
  end
end
