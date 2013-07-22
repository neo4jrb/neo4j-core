share_examples_for "Neo4j::Node" do
  context "with auto commit" do
    describe "class methods" do
      describe 'new' do

        subject do
          Neo4j::Node.new
        end
        its(:exist?) { should be_true }
        its(:neo_id) { should be_a(Fixnum) }
        its(:props) { should == {} }
      end

      describe 'load' do
        it "can load a node if it exists" do
          node1 = Neo4j::Node.new
          id1 = node1.neo_id
          node2 = Neo4j::Node.load(id1)
          node1.neo_id.should == node2.neo_id
        end

        it "returns nil if the node does not exist" do
          Neo4j::Node.load(71247427).should be_nil
        end
      end
    end

    describe 'instance methods' do

      let(:node) do
        Neo4j::Node.new
      end

      describe 'neo_id' do
        it "returns the neo4j id" do
          neo_id = node.neo_id
          neo_id.should be_a(Fixnum)
        end
      end

      describe 'del' do
        it "deletes the node" do
          n = Neo4j::Node.new
          n.should exist
          n.del
          n.should_not exist
        end

        it 'raise an exception if node does not exist' do
          n = Neo4j::Node.new
          n.del
          Proc.new { n.del }.should raise_error
        end
      end

      describe '[] and []=' do
        it "can write and read String" do
          node[:foo] = 'bar'
          node[:foo].should == 'bar'
        end

        it "can write and read Fixnum" do
          node[:foo] = 42
          node[:foo].should == 42
        end

        it "can write and read Float" do
          node[:foo] = 1.23
          node[:foo].should == 1.23
        end

        it "can write and read Boolean" do
          node[:foo] = false
          node[:bar] = true
          node[:foo].should be_false
          node[:bar].should be_true
        end

        it "raise exception for illegal values" do
          Proc.new { node[:illegal_thing] = Object.new }.should raise_error
          node[:illegal_thing].should be_nil
        end

        it "returns nil if it does not exist" do
          node[:this_does_not_exist].should == nil
        end

        it "removes the property when setting it to nil" do
          node[:foo] = 2
          node[:foo].should == 2
          node[:foo] = nil
          node[:foo].should be_nil
        end

      end
    end
  end

end
