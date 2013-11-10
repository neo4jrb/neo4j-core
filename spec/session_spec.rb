require "spec_helper"

module Neo4j
  describe Session do
    context "invalid type" do
      its "initialization should raise a InvalidSessionType error" do
        expect { Session.new(:invalid_type, "invalid/valid url") }.to raise_error(Session::InvalidSessionType)
      end
    end

    context "rest implementation" do
      describe "instance methods" do
        subject do
          Session.new :rest, "http://localhost:7474/"
          Session.current
        end
        its(:start) { should be_true }
        its(:class) { should be Session::Rest }
        its(:stop) { should be_true }
      end

      describe "class methods" do
      end
    end

    context "embedded implementation" do
      describe "instance methods" do
        subject do
          Session.new :embedded, Helpers::Embedded::PATH
          Session.current
        end
        its(:start) { should be_true }
        its(:class) { should be Session::Rest }
        its(:stop) { should be_true }
      end

      describe "class methods" do
      end
    end
  end
end
