require "spec_helper"

module Neo4j
  describe Session do
    context "invalid type" do
      its "initialization should raise a InvalidSessionType error" do
        expect { Session.new(:invalid_type, "invalid/valid url") }.to raise_error(Session::InvalidSessionType)
      end
    end
  end
end
