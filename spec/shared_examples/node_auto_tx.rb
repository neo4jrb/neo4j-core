RSpec.shared_examples 'Neo4j::Node auto tx' do
  let(:node_a) { Neo4j::Node.create(name: 'a') }
  let(:node_b) { Neo4j::Node.create(name: 'b') }
  let(:node_c) { Neo4j::Node.create(name: 'c') }
  let(:node_d) { Neo4j::Node.create(name: 'd') }


  context 'with auto commit' do
    describe 'class methods' do
      describe 'create()' do
        subject { Neo4j::Node.create }

        its(:exist?) { should be true }
        its(:neo_id) { should be_a(Fixnum) }
        its(:props) { should == {} }
      end

      describe 'create(name: "kalle", age: 42)' do
        subject { Neo4j::Node.create(name: 'kalle', age: 42) }

        its(:exist?) { should be true }
        its(:neo_id) { should be_a(Fixnum) }
        its(:props) { should == {name: 'kalle', age: 42} }

        it 'read the properties using []' do
          expect(subject[:name]).to eq('kalle')
          expect(subject[:age]).to eq(42)
        end
      end

      describe "create(name: 'D\'Amore-Schamberger')" do
        subject { Neo4j::Node.create(name: "D'Amore-Schamberger") }

        it { is_expected.to be_persisted }
        its(:props) { is_expected.to eq(name: "D'Amore-Schamberger") }
      end

      describe 'create(name: "test\\usomething")' do
        subject { Neo4j::Node.create(name: 'test\\usomething') }

        it { is_expected.to be_persisted }
        its(:props) { is_expected.to eq(name: 'test\\usomething') }
      end

      describe 'create(name: "kalle", age: nil)' do
        subject { Neo4j::Node.create(name: 'kalle', age: nil) }

        it 'read the properties using []' do
          expect(subject[:name]).to eq('kalle')
          expect(subject[:age]).to be_nil
        end
      end

      describe 'load' do
        it 'can load a node if it exists' do
          node1 = Neo4j::Node.create
          id1 = node1.neo_id
          node2 = Neo4j::Node.load(id1)
          expect(node1.neo_id).to eq(node2.neo_id)
        end

        it 'returns nil if the node does not exist' do
          expect(Neo4j::Node.load(71_247_427)).to be_nil
        end
      end
    end

    describe 'instance methods' do
      let(:node) do
        Neo4j::Node.create
      end

      describe 'neo_id' do
        it 'returns the neo4j id' do
          neo_id = node.neo_id
          expect(neo_id).to be_a(Fixnum)
        end
      end

      describe 'del' do
        let(:n) { Neo4j::Node.create }
        it 'deletes the node' do
          expect(n).to exist
          n.del
          Neo4j::Transaction.current.close if Neo4j::Transaction.current
          expect(n).not_to exist
        end

        it 'does not raise an exception if node does not exist' do
          n.del
          Neo4j::Transaction.current.close if Neo4j::Transaction.current
          if Neo4j::Session.current.db_type == :server_db
            expect { n.del }.not_to raise_error
          else
            expect { n.del }.to raise_error(Java::OrgNeo4jGraphdb::NotFoundException)
          end
        end

        it 'does delete its relationships as well' do
          m = Neo4j::Node.create
          rel = n.create_rel(:friends, m)
          expect(rel).to exist
          n.del
          Neo4j::Transaction.current.close if Neo4j::Transaction.current
          expect(n).not_to exist
          expect(rel).not_to exist
        end

        it 'is aliased to delete' do
          n
          n.delete
          Neo4j::Transaction.current.close if Neo4j::Transaction.current
          expect(n).not_to exist
        end

        it 'is aliased to destroy' do
          n.destroy
          Neo4j::Transaction.current.close if Neo4j::Transaction.current
          expect(n).not_to exist
        end
      end

      describe 'labels' do
        it 'returns [] if there are no labels' do
          n = Neo4j::Node.create
          expect(n.labels.to_a).to eq([])
        end

        it 'returns all labels for the node' do
          n = Neo4j::Node.create({}, :label1, :label2)
          expect(n.labels.to_a).to include(:label1, :label2)
        end
      end

      describe '[] and []=' do
        it 'can write and read String' do
          node[:foo] = 'bar'
          expect(node[:foo]).to eq('bar')
        end

        it 'can write and read Fixnum' do
          node[:foo] = 42
          expect(node[:foo]).to eq(42)
        end

        it 'can write and read Float' do
          node[:foo] = 1.23
          expect(node[:foo]).to eq(1.23)
        end

        it 'can write and read Boolean' do
          node[:foo] = false
          node[:bar] = true
          expect(node[:foo]).to be false
          expect(node[:bar]).to be true
        end

        context 'reading/writing Arrays' do
          it 'can handle ruby arrays of Fixnum' do
            node[:foo] = [1, 2, 3]
            expect(node[:foo]).to eq [1, 2, 3]
            expect(node[:foo]).to be_an(Array)
          end

          it 'can handle ruby arrays of strings' do
            node[:foo] = %w(hej hopp)
            expect(node[:foo]).to eq %w(hej hopp)
          end

          it 'can handle ruby arrays of strings' do
            node[:foo] = %w(hej hopp)
            expect(node[:foo]).to eq %w(hej hopp)
          end

          it 'can handle ruby arrays of true,false' do
            node[:foo] = [false, true, true]
            expect(node[:foo]).to eq [false, true, true]
          end

          it 'can handle ruby arrays of floats' do
            node[:foo] = [3.14, 4.24]
            expect(node[:foo]).to eq [3.14, 4.24]
          end
        end

        it 'raise exception for illegal values' do
          expect { node[:illegal_thing] = Object.new }.to raise_error(Neo4j::PropertyValidator::InvalidPropertyException)
          expect(node[:illegal_thing]).to be_nil
        end

        it 'returns nil if it does not exist' do
          expect(node[:this_does_not_exist]).to eq(nil)
        end

        it 'removes the property when setting it to nil' do
          node[:foo] = 2
          expect(node[:foo]).to eq(2)
          node[:foo] = nil
          expect(node[:foo]).to be_nil
        end
      end

      describe 'unwrapped' do
        let!(:node) { Neo4j::Node.create }
        after { node.destroy }

        it 'prevents calling of `wrapper`' do
          expect(node).not_to receive(:wrapper)
          result = Neo4j::Session.current.query.match('(n) WHERE ID(n) = {id}').params(id: node.neo_id).unwrapped.pluck(:n).first
          expect(result).to respond_to(:neo_id)
        end
      end

      describe 'props' do
        let(:label) { "L#{unique_random_number}".to_sym }

        let!(:node) do
          Neo4j::Node.create({age: 2}, label)
        end

        def get_node_from_query_result
          Neo4j::Session.query.match(n: label).pluck(:n).first
        end

        it 'holds the current value' do
          n = get_node_from_query_result
          expect(n.props).to eq(age: 2)
          n[:age] = 3
          expect(n.props).to eq(age: 3)
        end

        describe 'refresh' do
          it 'will keep the old value unless node is refreshed for the server_db' do
            n = get_node_from_query_result
            expect(n[:age]).to eq(2)
            get_node_from_query_result[:age] = 4

            if Neo4j::Session.current.db_type == :embedded_db
              expect(n[:age]).to eq(4)
              expect(n.props).to eq(age: 4)
            else
              expect(n[:age]).to eq(2)
              expect(n.props).to eq(age: 2)
            end
          end


          it 'will read from database again after refresh' do
            n = get_node_from_query_result
            expect(n[:age]).to eq(2)
            get_node_from_query_result[:age] = 4
            n.refresh
            expect(n[:age]).to eq(4)
            expect(n.props).to eq(age: 4)
          end
        end
      end

      describe 'props=' do
        it 'replace old properties with new properties' do
          n = Neo4j::Node.create(age: 2, foo: 'bar')
          expect(n.props).to eq(age: 2, foo: 'bar')
          n.props = {name: 'andreas', age: 21}
          expect(n.props).to eq(name: 'andreas', age: 21)
        end

        it 'allows update with empty hash, will remove all props' do
          n = Neo4j::Node.create(age: 2, foo: 'bar')
          expect(n.props).to eq(age: 2, foo: 'bar')
          n.props = {}
          expect(n.props).to eq({})
        end
      end

      describe 'update_props' do
        it 'keeps old properties' do
          a = Neo4j::Node.create(old: 'a')
          a.update_props({})
          expect(a[:old]).to eq('a')

          a.update_props(new: 'b', name: 'foo')
          expect(a[:old]).to eq('a')
          expect(a[:new]).to eq('b')
          expect(a[:name]).to eq('foo')
        end

        it 'replace old properties' do
          a = Neo4j::Node.create(old: 'a')
          a.update_props(old: 'b')
          expect(a[:old]).to eq('b')
        end

        it 'removes properties with nil values' do
          # skip "Failing test for https://github.com/andreasronge/neo4j/issues/319"
          a = Neo4j::Node.create(old: 'a', new: 'b')
          expect(a.props).to eq(old: 'a', new: 'b')
          a.update_props(old: nil)
          expect(a.props).to eq(new: 'b')
        end

        it 'can set boolean value' do
          a = Neo4j::Node.create(old: false)
          expect(a[:old]).to eq(false)
          a.update_props(old: true)
          expect(a[:old]).to eq(true)
          a.update_props(old: false)
          expect(a[:old]).to eq(false)
        end

        it 'replace escape properties' do
          a = Neo4j::Node.create
          a.update_props(old: "\"'")
          expect(a[:old]).to eq("\"'")
        end

        it 'allows strange property names' do
          a = Neo4j::Node.create
          a.update_props('1' => 2, 'h#a' => 'ho')
          expect(a.props).to eq('1'.to_sym => 2, 'h#a'.to_sym => 'ho')
        end
      end

      describe 'create_rel' do
        it 'can create a new relationship' do
          rel = node_a.create_rel(:best_friend, node_b)
          expect(rel.neo_id).to be_a_kind_of(Fixnum)
          expect(rel.exist?).to be true
        end


        it 'has a start_node and end_node' do
          rel = node_a.create_rel(:best_friend, node_b)
          expect(rel.start_node.neo_id).to eq(node_a.neo_id)
          expect(rel.end_node.neo_id).to eq(node_b.neo_id)
        end

        it 'can create a new relationship with properties' do
          rel = node_a.create_rel(:best_friend, node_b, since: 2001)
          expect(rel[:since]).to eq(2001)
          expect(rel.exist?).to be true
        end
      end

      describe 'rel?' do
        it 'returns true relationship if there is only one' do
          node_a.create_rel(:knows, node_b)
          expect(node_a.rel?(type: :knows, dir: :outgoing)).to be true
          expect(node_a.rel?(type: :knows, dir: :incoming)).to be false
          expect(node_a.rel?(type: :knows)).to be true
        end

        it 'returns true if there is more then one matching relationship' do
          node_a.create_rel(:knows, node_b)
          node_a.create_rel(:knows, node_b)
          expect(node_a.rel?(type: :knows)).to be true
          expect(node_a.rel?(dir: :outgoing, type: :knows)).to be true
          expect(node_a.rel?(dir: :both, type: :knows)).to be true
          expect(node_a.rel?(dir: :incoming, type: :knows)).to be false
        end
      end

      describe 'rel' do
        it 'returns the relationship if there is only one' do
          rel = node_a.create_rel(:knows, node_b)
          expect(node_a.rel(type: :knows, dir: :outgoing)).to eq(rel)
          expect(node_a.rel(type: :knows, dir: :incoming)).to be_nil
          expect(node_a.rel(type: :knows)).to eq(rel)
        end

        it 'raise an exception if there are more then one matching relationship' do
          node_a.create_rel(:knows, node_b)
          node_a.create_rel(:knows, node_b)
          expect { node_a.rel(:knows) }.to raise_error(NoMethodError)
        end
      end


      describe 'node' do
        describe 'node()' do
          it 'returns a node if there is any outgoing,incoming relationship of any type to it' do
            node_a.create_rel(:work, node_b)
            expect(node_a.node).to eq(node_b)
          end

          it 'returns nil if there is no relationships' do
            expect(node_a.node).to be_nil
          end

          it 'raise an exception if there are more then one relationship' do
            node_a.create_rel(:work, node_b)
            node_a.create_rel(:work, node_b)
            expect { expect(node_a.node).to eq(node_b) }.to raise_error(ArgumentError)
          end
        end

        describe 'node(dir: :outgoing, type: :friends)' do
          it 'returns a node if there is any outgoing,incoming relationship of any type to it' do
            node_a.create_rel(:friends, node_b)
            expect(node_a.node(dir: :outgoing, type: :friends)).to eq(node_b)
            expect(node_a.node(dir: :incoming, type: :friends)).to be_nil
            expect(node_a.node(dir: :outgoing, type: :knows)).to be_nil
          end
        end
      end

      describe 'nodes' do
        describe 'nodes()' do
          it 'returns incoming and outgoing nodes of any type' do
            node_a.create_rel(:bar, node_b)
            node_a.create_rel(:bar, node_c)
            node_d.create_rel(:foo, node_a)
            expect(node_a.nodes.to_a).to match_array([node_b, node_c, node_d])
          end
        end

        describe 'nodes(type: :work)' do
          it 'returns incoming and outgoing nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            node_b.create_rel(:work, node_a)
            expect(node_a.nodes(type: :work).to_a).to eq([node_b])
            expect(node_a.nodes(type: :best_friend).to_a).to eq([node_b])
            expect(node_a.nodes(type: :unknown_rel)).to be_empty
          end
        end

        describe 'nodes(dir: :outgoing)' do
          it 'finds outgoing nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            node_b.create_rel(:work, node_a)
            expect(node_a.nodes(dir: :outgoing).to_a).to eq([node_b])
            expect(node_b.nodes(dir: :outgoing).to_a).to eq([node_a])
            expect(node_c.nodes(dir: :outgoing)).to be_empty
          end
        end

        describe 'nodes(dir: :incoming)' do
          it 'finds outgoing nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            expect(node_a.nodes(dir: :incoming)).to be_empty
            expect(node_b.nodes(dir: :incoming).to_a).to eq([node_a])
          end
        end

        describe 'nodes(dir: incoming, type: work)' do
          it 'finds incoming nodes of any type' do
            node_a.create_rel(:best_friend, node_b)
            node_b.create_rel(:work, node_a)

            expect(node_a.nodes(dir: :incoming, type: :work).to_a).to eq([node_b])
            expect(node_b.nodes(dir: :incoming, type: :work).to_a).to be_empty
          end
        end

        describe 'rels(between: node_b)' do
          it 'finds all relationships between two nodes' do
            node_a.create_rel(:work, node_b)
            node_a.create_rel(:work, node_c)
            expect(node_a.nodes(between: node_b).to_a).to eq([node_b])
            expect(node_a.nodes(between: node_c).to_a).to eq([node_c])
            expect(node_a.nodes(between: node_d).to_a).to be_empty
          end
        end
      end

      describe 'rels' do
        describe 'rels()' do
          it 'finds relationship of any dir and any type' do
            rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
            rel_b = node_b.create_rel(:work, node_a)
            expect(node_a.rels.count).to eq(2)
            expect(node_a.rels.to_a).to match_array([rel_a, rel_b])
          end

          it 'returns an empty enumerable if there are no relationships' do
            expect(node_a.rels).to be_empty
          end
        end

        describe 'invalid values' do
          it 'validates dir' do
            expect { node_a.rels(dir: :incoming) }.not_to raise_error
            expect { node_a.rels(dir: :outgoing) }.not_to raise_error
            expect { node_a.rels(dir: :both) }.not_to raise_error
            expect { node_a.rels(dir: :invalid) }.to raise_error(RuntimeError)
          end

          it 'validates expected keys' do
            expect { node_a.rels }.not_to raise_error
            expect { node_a.rels(invalid: true) }.to raise_error(RuntimeError)
          end
        end

        describe 'rels(type: :work)' do
          it 'finds any dir of one relationship type' do
            rel_a = node_a.create_rel(:best_friend, node_b, age: 42)
            rel_b = node_b.create_rel(:work, node_a)
            expect(node_a.rels(type: :work).to_a).to eq([rel_b])
            expect(node_a.rels(type: :best_friend).to_a).to eq([rel_a])
          end
        end

        describe 'rels(dir: outgoing)' do
          it 'finds outgoing rels of any type' do
            rel_a = node_a.create_rel(:best_friend, node_b)
            rel_b = node_b.create_rel(:work, node_a)
            expect(node_a.rels(dir: :outgoing).to_a).to eq([rel_a])
            expect(node_b.rels(dir: :outgoing).to_a).to eq([rel_b])
          end
        end

        describe 'rels(dir: incoming)' do
          it 'finds incoming rels of any type' do
            rel_a = node_a.create_rel(:best_friend, node_b)
            rel_b = node_b.create_rel(:work, node_a)
            expect(node_a.rels(dir: :incoming).to_a).to eq([rel_b])
            expect(node_b.rels(dir: :incoming).to_a).to eq([rel_a])
          end
        end

        describe 'rels(dir: incoming, type: work)' do
          it 'finds incoming rels of any type' do
            rel_b = node_b.create_rel(:work, node_a)
            rel_c = node_a.create_rel(:work, node_b)

            expect(node_a.rels(dir: :incoming, type: :work).to_a).to eq([rel_b])
            expect(node_a.rels(dir: :outgoing, type: :work).to_a).to eq([rel_c])
          end
        end

        describe 'rels(between: node_b)' do
          it 'finds all relationships between two nodes' do
            rel_a = node_a.create_rel(:work, node_b)
            rel_b = node_a.create_rel(:work, node_c)
            expect(node_a.rels(between: node_b).to_a).to eq([rel_a])
            expect(node_a.rels(between: node_c).to_a).to eq([rel_b])
          end

          it 'can be combined with type, between: node_b, type: friends' do
            rel_a = node_a.create_rel(:work, node_b)
            rel_b = node_a.create_rel(:work, node_c)
            rel_c = node_a.create_rel(:friends, node_b)
            rel_d = node_a.create_rel(:friends, node_c)
            expect(node_a.rels(between: node_b, type: :friends).to_a).to eq([rel_c])
            expect(node_a.rels(between: node_c, type: :friends).to_a).to eq([rel_d])
            expect(node_a.rels(between: node_b, type: :work).to_a).to eq([rel_a])
            expect(node_a.rels(between: node_c, type: :work).to_a).to eq([rel_b])
          end

          it 'can be combined with direction' do
            rel_a = node_a.create_rel(:work, node_b)
            rel_b = node_a.create_rel(:work, node_c)
            rel_c = node_a.create_rel(:friends, node_b)
            rel_d = node_a.create_rel(:friends, node_c)
            expect(node_a.rels(between: node_b, dir: :both).to_a).to match_array([rel_c, rel_a])
            expect(node_a.rels(between: node_c, dir: :both).to_a).to match_array([rel_d, rel_b])
            expect(node_a.rels(between: node_b, dir: :outgoing).to_a).to match_array([rel_a, rel_c])
            expect(node_a.rels(between: node_c, dir: :incoming).to_a).to be_empty
            expect(node_c.rels(between: node_a, dir: :incoming).to_a).to match_array([rel_b, rel_d])
          end
        end
      end
    end
  end
end
