require "spec_helper"

module Neo4j
  describe Node do
    context "invalid session" do
      its "initialization" do
        fake_session = :Fake_Session
        expect { Node.new({name: "Ujjwal"}, :label1, :label2, fake_session) }.to raise_error(Session::InvalidSessionType)
      end
    end
  end
end