share_examples_for "Neo4j::Node auto tx" do
  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }
  let(:node_c) { Neo4j::Node.create(name: 'c') }
  let(:node_d) { Neo4j::Node.create(name: 'd') }


  context "with auto commit" do
    describe "class methods" do
      describe 'create()' do

        subject do
          Neo4j::Node.create
        end
        its(:exist?) { should be_true }
        its(:neo_id) { should be_a(Fixnum) }
        its(:props) { should == {} }
      end

      describe 'create(name: "kalle", age: 42)' do

        subject do
          Neo4j::Node.create(name: 'kalle', age: 42)
        end
        its(:exist?) { should be_true }
        its(:neo_id) { should be_a(Fixnum) }
        its(:props) { should == { name: 'kalle', age: 42} }

        it 'read the properties using []' do
          subject[:name].should == 'kalle'
          subject[:age].should == 42
        end
      end


      describe 'create(name: "kalle", age: nil)' do

        subject do
          Neo4j::Node.create(name: 'kalle', age: nil)
        end
        it 'read the properties using []' do
          subject[:name].should == 'kalle'
          subject[:age].should be_nil
        end
      end

      unless defined? JRUBY_VERSION
        # not needed in jruby, see https://github.com/andreasronge/neo4j-core/pull/53
        describe 'broken escape sequence create(name: "ka\putt")' do

          subject do
            Neo4j::Node.create(name: 'ka\putt')
          end
          its(:exist?) { should be_true }
          its(:neo_id) { should be_a(Fixnum) }
          its(:props) { should == { name: 'kaputt'} }

          it 'read the properties using []' do
            subject[:name].should == 'kaputt'
          end
        end
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

        it 'does delete its relationships as well' do
          n = Neo4j::Node.create
          m = Neo4j::Node.create
          rel = n.create_rel(:friends, m)
          rel.should exist
          n.del
          n.should_not exist
          rel.should_not exist
        end
      end

      describe 'labels' do
        it 'returns [] if there are no labels' do
          n = Neo4j::Node.create
          n.labels.to_a.should == []
        end

        it 'returns all labels for the node' do
          n = Neo4j::Node.create({}, :label1, :label2)
          n.labels.to_a.should == [:label1, :label2]
        end
      end

      describe '[] and []=' do
        it "can write and read String" do
          node[:foo] = 'bar'
          node[:foo].should == 'bar'
        end

        it "can write and read Fixnum" do
          node[:foo] = 42
          node[:foo].should eq(42)
        end

        it "can write and read Float" do
          node[:foo] = 1.23
          node[:foo].should eq(1.23)
        end

        it "can write and read Boolean" do
          node[:foo] = false
          node[:bar] = true
          node[:foo].should be_false
          node[:bar].should be_true
        end

        it "raise exception for illegal values" do
          Proc.new { node[:illegal_thing] = Object.new }.should raise_error(Neo4j::PropertyValidator::InvalidPropertyException)
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

      describe 'props=' do
        it "replace old properties with new properties" do
          n = Neo4j::Node.create(age: 2, foo: 'bar')
          n.props.should == {age: 2, foo: 'bar'}
          n.props={name: 'andreas', age: 21}
          n.props.should == {name: 'andreas', age: 21}
        end

        it 'allows update with empty hash, will remove all props' do
          n = Neo4j::Node.create(age: 2, foo: 'bar')
          n.props.should == {age: 2, foo: 'bar'}
          n.props={}
          n.props.should == {}
        end
      end

      describe 'update_props' do
        it 'keeps old properties' do
          a = Neo4j::Node.create(old: 'a')
          a.update_props({})
          a[:old].should == 'a'

          a.update_props({new: 'b', name: 'foo'})
          a[:old].should == 'a'
          a[:new].should == 'b'
          a[:name].should == 'foo'
        end

        it 'replace old properties' do
          a = Neo4j::Node.create(old: 'a')
          a.update_props({old: 'b'})
          a[:old].should == 'b'
        end

        it 'removes properties with nil values' do
          #pending "Failing test for https://github.com/andreasronge/neo4j/issues/319"
          a = Neo4j::Node.create(old: 'a', new: 'b')
          a.props.should == {old: 'a', new: 'b'}
          a.update_props(old: nil)
          a.props.should == {new: 'b'}
        end

        it 'can set boolean value' do
          a = Neo4j::Node.create(old: false)
          a[:old].should eq(false)
          a.update_props({old: true})
          a[:old].should eq(true)
          a.update_props({old: false})
          a[:old].should eq(false)
        end

        it 'replace escape properties' do
          a = Neo4j::Node.create
          a.update_props(old: "\"'")
          a[:old].should == "\"'"
        end

        it 'allows strange property names' do
          a = Neo4j::Node.create
          a.update_props({"1" => 2, " ha " => "ho"})
          a.props.should == {:"1"=>2, :" ha "=>"ho"}
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

      describe 'rel?' do
        it "returns true relationship if there is only one" do
          node_a.create_rel(:knows, node_b)
          node_a.rel(type: :knows, dir: :outgoing).should be_true
          node_a.rel(type: :knows, dir: :incoming).should be_false
          node_a.rel(type: :knows).should be_true
        end

        it 'returns true if there is more then one matching relationship' do
          node_a.create_rel(:knows, node_b)
          node_a.create_rel(:knows, node_b)
          node_a.rel?(type: :knows).should be_true
          node_a.rel?(dir: :outgoing, type: :knows).should be_true
          node_a.rel?(dir: :both, type: :knows).should be_true
          node_a.rel?(dir: :incoming, type: :knows).should be_false
        end

      end

      describe 'rel' do
        it "returns the relationship if there is only one" do
          rel = node_a.create_rel(:knows, node_b)
          node_a.rel(type: :knows, dir: :outgoing).should == rel
          node_a.rel(type: :knows, dir: :incoming).should be_nil
          node_a.rel(type: :knows).should == rel
        end

        it 'raise an exception if there are more then one matching relationship' do
          node_a.create_rel(:knows, node_b)
          node_a.create_rel(:knows, node_b)

          expect{node_a.rel(:knows)}.to raise_error
        end
      end


      describe 'node' do
        describe 'node()' do
          it 'returns a node if there is any outgoing,incoming relationship of any type to it' do
            node_a.create_rel(:work, node_b)
            node_a.node().should == node_b
          end

          it 'returns nil if there is no relationships' do
            node_a.node().should be_nil
          end

          it 'raise an exception if there are more then one relationship' do
            node_a.create_rel(:work, node_b)
            node_a.create_rel(:work, node_b)
            expect{ node_a.node().should == node_b}.to raise_error
          end
        end

        describe 'node(dir: :outgoing, type: :friends)' do
          it 'returns a node if there is any outgoing,incoming relationship of any type to it' do
            node_a.create_rel(:friends, node_b)
            node_a.node(dir: :outgoing, type: :friends).should == node_b
            node_a.node(dir: :incoming, type: :friends).should be_nil
            node_a.node(dir: :outgoing, type: :knows).should be_nil
          end

        end

      end

      describe 'nodes' do

        describe 'nodes()' do
          it 'returns incoming and outgoing nodes of any type' do
            node_a.create_rel(:bar, node_b)
            node_a.create_rel(:bar, node_c)
            node_d.create_rel(:foo, node_a)
            node_a.nodes.to_a.should =~ [node_b, node_c, node_d]
          end
        end

        describe 'nodes(type: :work)' do
          it 'returns incoming and outgoing nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            node_b.create_rel(:work, node_a)
            node_a.nodes(type: :work).to_a.should == [node_b]
            node_a.nodes(type: :best_friend).to_a.should == [node_b]
            node_a.nodes(type: :unknown_rel).should be_empty
          end
        end

        describe 'nodes(dir: :outgoing)' do
          it 'finds outgoing nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            node_b.create_rel(:work, node_a)
            node_a.nodes(dir: :outgoing).to_a.should == [node_b]
            node_b.nodes(dir: :outgoing).to_a.should == [node_a]
            node_c.nodes(dir: :outgoing).should be_empty

          end
        end

        describe 'nodes(dir: :incoming)' do
          it 'finds outgoing nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            node_a.nodes(dir: :incoming).should be_empty
            node_b.nodes(dir: :incoming).to_a.should == [node_a]
          end
        end

        describe 'nodes(dir: incoming, type: work)' do
          it 'finds incoming nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            node_b.create_rel(:work, node_a)

            node_a.nodes(dir: :incoming, type: :work).to_a.should == [node_b]
            node_b.nodes(dir: :incoming, type: :work).to_a.should be_empty
          end
        end

        describe 'rels(between: node_b)' do
          it 'finds all relationships between two nodes' do
            node_a.create_rel(:work, node_b)
            node_a.create_rel(:work, node_c)
            node_a.nodes(between: node_b).to_a.should == [node_b]
            node_a.nodes(between: node_c).to_a.should == [node_c]
            node_a.nodes(between: node_d).to_a.should be_empty
          end

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

          it 'can be combined with type, between: node_b, type: friends' do
            rel_a = node_a.create_rel(:work, node_b)
            rel_b = node_a.create_rel(:work, node_c)
            rel_c = node_a.create_rel(:friends, node_b)
            rel_d = node_a.create_rel(:friends, node_c)
            node_a.rels(between: node_b, type: :friends).to_a.should == [rel_c]
            node_a.rels(between: node_c, type: :friends).to_a.should == [rel_d]
            node_a.rels(between: node_b, type: :work).to_a.should == [rel_a]
            node_a.rels(between: node_c, type: :work).to_a.should == [rel_b]
          end

          it 'can be combined with direction' do
            rel_a = node_a.create_rel(:work, node_b)
            rel_b = node_a.create_rel(:work, node_c)
            rel_c = node_a.create_rel(:friends, node_b)
            rel_d = node_a.create_rel(:friends, node_c)
            node_a.rels(between: node_b, dir: :both).to_a.should =~ [rel_c, rel_a]
            node_a.rels(between: node_c, dir: :both).to_a.should =~ [rel_d, rel_b]
            node_a.rels(between: node_b, dir: :outgoing).to_a.should =~ [rel_a, rel_c]
            node_a.rels(between: node_c, dir: :incoming).to_a.should be_empty
            node_c.rels(between: node_a, dir: :incoming).to_a.should =~ [rel_b, rel_d]
          end
        end

      end
    end
  end

end
