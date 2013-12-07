module Neo4j
  shared_examples "PropertyContainer" do |container|
    describe "instance method" do
      describe "[properties]" do
        context "when the properties exist" do
          it "returns the values of those properties" do
            expect(container[:name, :email]).to eq(["Ujjwal", "ujjwalthaakar@gmail.com"])
          end
        end

        context "when the property doesn't exist" do
          it "returns nil" do
            expect(container[:favourite_language]).to be_nil
            expect(container[:favourite_database]).to be_nil
          end
        end

        context "existing and non existing properties" do
          it "returns correct values for existing properties and nil otherwise" do
            expect(container[:name, :favourite_language, :email, :favourite_database]).to eq(["Ujjwal", nil, "ujjwalthaakar@gmail.com", nil])
          end
        end
      end

      describe "[properties] = values" do
        context "when the values are given" do
          it "sets properties to the values" do
            container[:name, :email, :not_considered] = "Andreas Ronge", "andreas.ronge@gmail.com"
            expect(container[:name, :email]).to eq(["Andreas Ronge", "andreas.ronge@gmail.com"])

            container[:name, :email] = "Andreas Ronge", "andreas.ronge@gmail.com", "not considered"
            expect(container[:name, :email]).to eq(["Andreas Ronge", "andreas.ronge@gmail.com"])
          end
        end

        context "value is nil" do
          context "when the properties exist" do
            it "removes the properties" do
              container[:name, :email] = nil, nil
              expect(container[:name, :email]).to eq([nil, nil])
            end
          end

          context "when the property doesn't exist" do
            it "returns nil" do
              container[:favourite_language] = nil
              expect(container[:favourite_language]).to be_nil
            end
          end
        end
      end

      describe "props" do
        it "should give a hash of all properties and values" do
          expect(container.props).to eq({"name" => "Ujjwal", "email" => "ujjwalthaakar@gmail.com"})
        end
      end

      describe "props=(attributes)" do
        it "should reset all properties" do
          container.props = {sex: "Male", "birthday" => "30/2/2001"}
          expect(container.props).to eq({"sex" => "Male", "birthday" => "30/2/2001"})
        end
      end

      describe "delete" do
        it "deletes the container" do
          container.delete
          expect { container[:name] }.to raise_error(StandardError)
        end
      end
    end
  end
end
