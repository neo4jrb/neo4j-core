require "spec_helper"

module Neo4j
  describe Session::Embedded, api: :embedded do
    describe "instance method" do
      before :all do
        @session = Session.new :embedded, Helpers::Embedded.tmp_path
      end

      describe "start" do
        it "should be true if successful" do
          expect(@session.start).to be_true
        end
      end

      describe "class" do
        it "should be Session::Embedded" do
          expect(@session.class).to be Session::Embedded
        end
      end

      describe "stop" do
        it "should be true if successful" do
          expect(@session.stop).to be_true
        end
      end

      describe "running?" do
        before :all do
          @another_session = Session.new :embedded, Helpers::Embedded.tmp_path
        end

        context "before the server has started" do
          it "should be false" do
            p @another_session != nil
            expect(@another_session.running?).to be_false
          end
        end

        context "after the server has started" do
          it "should be true" do
            @another_session.start
            expect(@another_session.running?).to be_true
          end
        end

        context "after the server has stopped" do
          it "should be false" do
            @another_session.stop
            expect(@another_session.running?).to be_false
          end
        end
      end
    end

    describe "class method" do
    end
  end
end
