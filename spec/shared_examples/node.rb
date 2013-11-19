module Neo4j
  shared_examples "Node" do
    let(:api) { example.metadata[:api] }
    let (:another_session) do
      another_session = Session.new(api)
      another_session.start
      another_session
    end

    describe "instance method" do
      let(:node) { Node.new({name: "Ujjwal", email: "ujjwalthaakar@gmail.com"}, :User, :Programmer) }

      describe "[properties]" do
        context "when the properties exist" do
          it "returns the values of those properties" do
            expect(node[:name, :email]).to eq(["Ujjwal", "ujjwalthaakar@gmail.com"])
          end
        end

        context "when the property doesn't exist" do
          it "returns nil" do
            expect(node[:favourite_language]).to be_nil
            expect(node[:favourite_database]).to be_nil
          end
        end
      end

      describe "[properties] = values" do
        context "when the values are given" do
          it "sets properties to the values" do
            node[:name, :email, :not_considered] = "Andreas Ronge", "andreas.ronge@gmail.com"
            expect(node[:name, :email]).to eq(["Andreas Ronge", "andreas.ronge@gmail.com"])

            node[:name, :email] = "Andreas Ronge", "andreas.ronge@gmail.com", "not considered"
            expect(node[:name, :email]).to eq(["Andreas Ronge", "andreas.ronge@gmail.com"])
          end
        end

        context "value is nil" do
          context "when the properties exist" do
            it "removes the properties" do
              node[:name, :email] = nil, nil
              expect(node[:name, :email]).to be_empty
            end
          end

          context "when the property doesn't exist" do
            it "returns nil" do
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
          expect(node[:favourite_language]).to include("Ruby")
          expect(node[:favourite_database]).to include("Neo4J")
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
            expect(node[:name, :email]).to eq(["Ujjwal", "ujjwalthaakar@gmail.com"])
          end
        end

        context "using another session" do
          let(:another_node) { Node.new({name: "Andreas Ronge", email: "andreas.ronge@gmail.com"}, another_session) }
          it "creates a node in that session" do
            expect(another_node).to be_an_instance_of(described_class)
          end

          it "has the correct properties" do
            expect(another_node[:name, :email]).to eq(["Andreas Ronge", "andreas.ronge@gmail.com"])
          end
        end
      end

      describe "load(id)" do
        let(:node) { Node.new name: "Steve Wozniak", email: "steve.wozniak@apple.com" }
        let(:same_node) { Node.load(node.id) }

        it "loads the node with the given neo id" do
          expect(same_node).to be_an_instance_of(described_class)
          expect(node).to eq(same_node)
        end

        it "has the correct properties" do
          expect(node[:name, :email]).to eq(same_node[:name, :email])
        end
      end
    end
  end
end
