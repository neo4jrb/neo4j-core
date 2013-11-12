require "spec_helper"

module Neo4j
  describe Node::Rest, api: :rest do
    describe "class method" do
      describe "new" do
        context "using current session" do
          it "creates a node" do
            node = Node.new name: "Ujjwal", email: "ujjwalthaakar@gmail.com"
            expect(node.name).to eq("Ujjwal")
            expect(node.email).to eq("ujjwalthaakar@gmail.com")
          end
        end

        context "using another session" do
          it "creates a node in that session" do
            another_session = Session.new :rest
            node = Node.new name: "Andreas Ronge", email: "andreas.ronge@gmail.com"
            expect(node[:name]).to eq("Andreas Ronge")
            expect(node[:email]).to eq("andreas.ronge@gmail.com")
          end
        end
      end

      describe "load" do
        it "loads the node with the given neo id" do
          node = Node.new name: "Steve Wozniak", email: "steve.wozniak@apple.com"
          id = node.id
          same_node = Node.load(id)
          expect(node.id).to eq(same_node.id)
          expect(node[:name]).to eq(same_node[:name])
          expect(node[:email]).to eq(same_node[:email])
        end
      end
    end
  end
end
