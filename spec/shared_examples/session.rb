module Neo4j
  shared_examples "Session" do
    describe "instance method" do
      let(:api) { example.metadata[:api] }
      let(:session) { Session.current }

      describe "start" do
        it "should be true if successful" do
          expect(session.start).to be_true
        end
      end

      describe "class" do
        it "should be #{described_class}" do
          expect(session).to be_an_instance_of(described_class)
        end
      end

      describe "stop" do
        it "should be true if successful" do
          expect(session.stop).to be_true
        end
      end

      describe "running?" do

        it "has different values in embedded mode" do
          if api == :embedded
            context "before the server has started" do
              it "should be false" do
                expect(another_session.running?).to be_false
              end
            end

            context "after the server has started" do
              it "should be true" do
                another_session.start
                expect(another_session.running?).to be_true
              end
            end

            context "after the server has stopped" do
              it "should be false" do
                another_session.stop
                expect(another_session.running?).to be_false
              end
            end
          end
        end
      end
    end

    describe "class method" do
    end
  end
end