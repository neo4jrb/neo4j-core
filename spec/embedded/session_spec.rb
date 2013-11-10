require "spec_helper"

module Neo4j
  describe Session::Embedded, api: :embedded do
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
