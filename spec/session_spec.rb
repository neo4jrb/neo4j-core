require "spec_helper"

module Neo4j
  describe Session do
    context "invalid type" do
      its "initialization should raise a InvalidSessionType error" do
        expect { Session.new(:invalid_type, "invalid/valid url") }.to raise_error(Session::InvalidSessionType)
      end
    end
  end

  describe Session::Rest do
    describe "instance method" do
      subject do
        Session.new :rest, "http://localhost:7474/"
      end
      its(:start) { should be_true }
      its(:class) { should be Session::Rest }
      its(:stop) { should be_true }
    end

    describe "class method" do
    end
  end

  describe Session::Embedded do
    describe "instance method" do
      subject do
        Session.new :embedded, Helpers::Embedded::PATH
      end
      its(:start) { should be_true }
      its(:class) { should be Session::Embedded }
      its(:stop) { should be_true }
    end

    describe "class method" do
    end
  end
end
