require "spec_helper"

module Neo4j
  describe Node do
    describe "class method new" do
      context "with invalid session" do
        it "raises error" do
          expect { Node.new({name: "Ujjwal"}, :label1, :label2, :Fake_Session) }.to raise_error(Session::InvalidSessionTypeError)
        end
      end
    end

    describe "class method load" do
      context "with invalid session" do
        it "raises error" do
          expect { Node.load(0, :Fake_Session) }.to raise_error(Session::InvalidSessionTypeError)
        end
      end
    end
  end
end