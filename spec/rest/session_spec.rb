require "spec_helper"

module Neo4j
  describe Session::Rest, api: :rest do
    describe "instance method" do
      subject { Session.current }
      its(:start) { should be_true }
      its(:class) { should be Session::Rest }
      its(:stop) { should be_true }
    end

    describe "class method" do
    end
  end
end
