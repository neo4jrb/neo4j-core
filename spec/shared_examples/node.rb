module Neo4j
  shared_examples "Node" do
    describe "instance method" do
      let(:node) { Node.new({name: "Ujjwal", email: "ujjwalthaakar@gmail.com"}, :User, :Programmer) }

      describe "[](property)" do
        context "when the property exists" do
          it "returns the value of that property" do
            expect(node[:name]).to eq("Ujjwal")
            expect(node[:email]).to eq("ujjwalthaakar@gmail.com")
          end
        end

        context "when the property doesn't exist" do
          it "returns nil" do
            expect(node[:favourite_language]).to be_nil
            expect(node[:favourite_database]).to be_nil
          end
        end
      end

      describe "[]=(property, value)" do
        context "when the value is a ruby object" do
          it "sets property to value" do
            node[:name] = "Andreas Ronge"
            expect(node[:name]).to eq("Andreas Ronge")
            node[:name] = "andreas.ronge@gmail.com"
            expect(node[:name]).to eq("andreas.ronge@gmail.com")
          end
        end

        context "value is nil" do
          context "when the property exists" do
            it "removes the property" do
              node[:name] = nil
              expect(node[:name]).to be_nil
              node[:email] = nil
              expect(node[:name]).to be_nil
            end
          end

          context "when the property doesn't exist" do
            it "does nothing" do
              node[:favourite_language] = nil
              expect(node[:favourite_language]).to be_nil
            end
          end
        end
      end

      describe "reset(attributes)" do
        it "resets the properties" do
          node.reset favourite_language: "Ruby", favourite_database: "Neo4J"
          expect(node[:name]).to be_nil
          expect(node[:email]).to be_nil
          expect(node[:favourite_language]).to eq("Ruby")
          expect(node[:favourite_database]).to eq("Neo4J")
        end
      end

      describe "delete" do
        it "deletes the node" do
          node.delete
          expect { node[:name] }.to raise_error(StandardError)
        end
      end
    end

    describe "class method" do
      describe "new(attributes, labels, session)" do
        context "using current session" do
          it "creates a node" do
            node = Node.new name: "Ujjwal", email: "ujjwalthaakar@gmail.com"
            expect(node).to be_an_instance_of(described_class)
            expect(node[:name]).to eq("Ujjwal")
            expect(node[:email]).to eq("ujjwalthaakar@gmail.com")
          end
        end

        context "using another session" do
          let(:another_session) { Session.new example.metadata[:api] }
          let(:another_node) { Node.new({name: "Andreas Ronge", email: "andreas.ronge@gmail.com"}, another_session) }
          it "creates a node in that session" do
            expect(another_node).to be_an_instance_of(described_class)
          end

          it "has the correct properties" do
            expect(another_node[:name]).to eq("Andreas Ronge")
            expect(another_node[:email]).to eq("andreas.ronge@gmail.com")
          end
        end
      end

      describe "load(id)" do
        it "loads the node with the given neo id" do
          node = Node.new name: "Steve Wozniak", email: "steve.wozniak@apple.com"
          id = node.id
          same_node = Node.load(id)
          expect(same_node).to be_an_instance_of(described_class)
          expect(node.id).to eq(same_node.id)
          expect(node[:name]).to eq(same_node[:name])
          expect(node[:email]).to eq(same_node[:email])
        end
      end
    end
  end
end
