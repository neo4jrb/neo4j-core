share_examples_for "Neo4j::Node auto tx" do
  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }
  let(:node_c) { Neo4j::Node.create(name: 'c') }

  context "with auto commit" do
    describe "class methods" do
      describe 'create' do

        subject do
          Neo4j::Node.create
        end
        its(:exist?) { should be_true }
        its(:neo_id) { should be_a(Fixnum) }
        its(:props) { should == {} }
      end

      describe 'load' do
        it "can load a node if it exists" do
          node1 = Neo4j::Node.create
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
        Neo4j::Node.create
      end

      describe 'neo_id' do
        it "returns the neo4j id" do
          neo_id = node.neo_id
          neo_id.should be_a(Fixnum)
        end
      end

      describe 'del' do
        it "deletes the node" do
          n = Neo4j::Node.create
          n.should exist
          n.del
          n.should_not exist
        end

        it 'raise an exception if node does not exist' do
          n = Neo4j::Node.create
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
          Proc.new { node[:illegal_thing] = Object.new }.should raise_error(Neo4j::InvalidPropertyException)
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

      describe 'create_rel' do

        it "can create a new relationship" do
          rel = node_a.create_rel(:best_friend, node_b)
          rel.neo_id.should be_a_kind_of(Fixnum)
          rel.exist?.should be_true
        end


        it 'has a start_node and end_node' do
          rel = node_a.create_rel(:best_friend, node_b)
          rel.start_node.neo_id.should == node_a.neo_id
          rel.end_node.neo_id.should == node_b.neo_id
        end

        it "can create a new relationship with properties" do
          rel = node_a.create_rel(:best_friend, node_b, since: 2001)
          rel[:since].should == 2001
          rel.exist?.should be_true
        end

      end

      describe 'rels' do

        describe 'rels()' do
          it 'finds relationship of any dir and any type' do
            rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
            rel_b = node_b.create_rel(:work, node_a)
            node_a.rels.count.should == 2
            node_a.rels.to_a.should =~ [rel_a, rel_b]
          end

          it "returns an empty enumerable if there are no relationships" do
            node_a.rels.should be_empty
          end
        end

        describe 'rels(type: :work)' do
          it 'finds any dir of one relationship type' do
            rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
            rel_b = node_b.create_rel(:work, node_a)
            node_a.rels(type: :work).to_a.should == [rel_b]
            node_a.rels(type: :best_friend).to_a.should == [rel_a]
          end
        end

        describe 'rels(dir: outgoing)' do
          it 'finds outgoing rels of any type' do
            rel_a = node_a.create_rel(:best_friend, node_b)
            rel_b = node_b.create_rel(:work, node_a)
            node_a.rels(dir: :outgoing).to_a.should == [rel_a]
            node_b.rels(dir: :outgoing).to_a.should == [rel_b]
          end
        end

        describe 'rels(dir: incoming)' do
          it 'finds incoming rels of any type' do
            rel_a = node_a.create_rel(:best_friend, node_b)
            rel_b = node_b.create_rel(:work, node_a)
            node_a.rels(dir: :incoming).to_a.should == [rel_b]
            node_b.rels(dir: :incoming).to_a.should == [rel_a]
          end
        end

        describe 'rels(dir: incoming, type: work)' do
          it 'finds incoming rels of any type' do
            rel_a = node_a.create_rel(:best_friend, node_b)
            rel_b = node_b.create_rel(:work, node_a)
            rel_c = node_a.create_rel(:work, node_b)
            rel_d = node_b.create_rel(:best_friend, node_a)

            node_a.rels(dir: :incoming, type: :work).to_a.should == [rel_b]
            node_a.rels(dir: :outgoing, type: :work).to_a.should == [rel_c]
          end
        end

        describe 'rels(between: node_b)' do
          it 'finds all relationships between two nodes' do
            rel_a = node_a.create_rel(:work, node_b)
            rel_b = node_a.create_rel(:work, node_c)
            node_a.rels(between: node_b).to_a.should == [rel_a]
            node_a.rels(between: node_c).to_a.should == [rel_b]
          end
        end

      end
    end
  end

end
