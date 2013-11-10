require "spec_helper"

module Neo4j
  describe Session::Rest, api: :rest do
    describe "instance method" do
      subject { Session.new :rest, "http://localhost:7474/" }
      its(:start) { should be_true }
      its(:class) { should be Session::Rest }
      its(:stop) { should be_true }
    end

    describe "class method" do
    end
  end
end
