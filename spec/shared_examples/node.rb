module Neo4j
  shared_examples "Node" do
    let(:api) { example.metadata[:api] }
    let (:another_session) do
      another_session = case api
      when :embedded
        Session.new(:embedded, Helpers::Embedded.test_path+'_another')
      when :rest
        Session.new(:rest, "http://localhost:4747")
      end
      another_session.start
      at_exit { another_session.stop }
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

        context "existing and non existing properties" do
          it "returns correct values for existing properties and nil otherwise" do
            expect(node[:name, :favourite_language, :email, :favourite_database]).to eq(["Ujjwal", nil, "ujjwalthaakar@gmail.com", nil])
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
              expect(node[:name, :email]).to eq([nil, nil])
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

      describe "props" do
        it "should give a hash of all properties and values" do
          expect(node.props).to eq({"name" => "Ujjwal", "email" => "ujjwalthaakar@gmail.com"})
        end
      end

      describe "props=(attributes)" do
        it "should reset all properties" do
          node.props = {sex: "Male", "birthday" => "30/2/2001"}
          expect(node.props).to eq({"sex" => "Male", "birthday" => "30/2/2001"})
        end
      end

      describe "delete" do
        it "deletes the node" do
          node.delete
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
