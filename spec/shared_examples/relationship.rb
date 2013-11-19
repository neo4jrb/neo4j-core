module Neo4j
  shared_examples "Relationship" do
    let(:api) { example.metadata[:api] }
    let (:another_session) do
      another_session = Session.new(api)
      another_session.start
      another_session
    end

    let(:start_node) { Node.new name: "Ujjwal Thaakar", age: 21 }
    let(:end_node) { Node.new name: "Andreas Ronge", nationaility: :sweedish }

    describe "instance method" do
      let(:rel) { Relationship.new start_node, :KNOWS, end_node, since: Date.parse('29/10/2013'), through: 'Gmail' }

      describe "name" do
        it "returns the name of the relationship" do
          expect(rel.name).to eq(:KNOWS)
        end
      end

      describe "[](property)" do
        context "when the property exists" do
          it "returns the value of that property" do
            expect(rel[:since]).to eq("29/10/2013")
            expect(node[:through]).to eq("Gmail")
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
            rel[:since] = "4/11/2013"
            expect(node[:since]).to eq("4/11/2013")
            rel[:through] = "Google+"
            expect(node[:through]).to eq("Google+")
          end
        end

        context "value is nil" do
          context "when the property exists" do
            it "removes the property" do
              node[:since] = nil
              expect(node[:since]).to be_nil
              node[:through] = nil
              expect(node[:through]).to be_nil
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

      describe "delete" do
        it "deletes the node" do
          node.delete
          expect { node[:since] }.to raise_error(StandardError)
        end
      end
    end

    describe "class method" do
      describe "new(name, start, end, attributes = {})" do
        let(:rel) { Relationship.new start_node, :FRIEND_OF, end_node, since: 2013, random_property: "who cares?" }

        it "returns nil if both nodes aren't from the same session" do
          another_session = Session.new :rest
          node_from_another_session = Node.new({name: "Ujjwal", email: "ujjwalthaakar@gmail.com"}, :from_another_session, another_session)
          rel = Relationship.new start_node, :NAME, node_from_another_session
          expect(rel).to be_nil
        end

        it "is an instance of the correct subclass" do
          expect(rel).to be_an_instance_of(described_class)
        end
      
        it "has the correct start node" do
          expect(rel.start).to eq(start_node)
        end

        it "has the correct end node"
          expect(rel.end).to eq(end_node)
        end

        it "has the correct properties"
          expect(rel[:since]).to eq(2013)
          expect(rel[:random_property]).to eq("who cares?")
        end

        it "does not have the wrong properties" do
          expect(rel[:invalid_property]).to be_nil
        end
      end

      describe "load(id)" do
        let(:rel) { Relationship.new(start_node, :CO_PROGRAMMER, end_node) }
        let(:same_rel) { Relationship.load(rel.id, Session.current) }
        it "load the relationship with the given id" do
          expect(rel.id).to eq(same_rel.id)
        end

        it "has the same start node"
          expect(rel.start_node).to eq(same_rel.start_node)
        end

        it "has the same end node"
          expect(rel.end_node).to eq(same_rel.end_node)
        end

        it "has the same name"
          expect(rel.name).to eq(same_rel.name)
        end
      end
    end
  end
end
