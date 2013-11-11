require "spec_helper"

module Neo4j::Node
  describe Rest do
    before :all do
      @session = Neo4j::Session.new :rest
      @another_session = Neo4j::Session.new :rest
    end

    describe "instance method" do
      describe "new" do
        context "using current session" do
          it "creates a node" do
            node1 = Neo4j::Node.new({name: "Ujjwal", email: "ujjwalthaakar@gmail.com"})
            expect(node1.name).to eq("Ujjwal")
            expect(node1.email).to eq("ujjwalthaakar@gmail.com")
          end
        end
      end
    end
  end
end
