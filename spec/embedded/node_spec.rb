require "spec_helper"

module Neo4j
  describe 'Embedded Node', api: :embedded do
    describe "instance method" do
      describe "new" do
        context "using current session" do
          it "creates a node" do
            node = Neo4j::Node.new name: "Ujjwal", email: "ujjwalthaakar@gmail.com"
            expect(node.name).to eq("Ujjwal")
            expect(node.email).to eq("ujjwalthaakar@gmail.com")
          end
        end
      end
    end
  end
end
