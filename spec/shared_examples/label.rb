RSpec.shared_examples 'Neo4j::Label' do
  before(:all) do
    r = Random.new
    @label1 = ('R1 ' + r.rand(0..1_000_000).to_s).to_sym
    @label2 = ('R2 ' + r.rand(0..1_000_000).to_s).to_sym
    @random_label = ('R3 ' + r.rand(0..1_000_000).to_s).to_sym
    @red1 = Neo4j::Node.create({}, @label1)
    @red2 = Neo4j::Node.create({}, @label1)
    @green = Neo4j::Node.create({}, @label2)
  end

  after(:all) { Neo4j::Label.drop_all_constraints  && Neo4j::Label.drop_all_indexes }

  describe 'Neo4j::Node' do
    describe 'add_labels' do
      it 'can add labels' do
        node = Neo4j::Node.create
        node.add_label(:new_label)
        expect(node.labels).to include(:new_label)
      end

      it 'escapes label names' do
        node = Neo4j::Node.create
        node.add_label(':bla')
        expect(node.labels).to include(:':bla')
      end

      it 'can set several labels in one go' do
        node = Neo4j::Node.create
        node.add_label(:one, :two, :three)
        expect(node.labels).to include(:one, :two, :three)
      end
    end

    describe 'set_label' do
      it 'replace old labels with new ones' do
        node = Neo4j::Node.create({}, :one, :two)
        node.set_label(:three)
        node = Neo4j::Node.load(node.neo_id)
        expect(node.labels).to eq([:three])
      end

      it 'allows setting several labels in one go' do
        node = Neo4j::Node.create({}, :one, :two)
        node.set_label(:two, :three, :four)
        node = Neo4j::Node.load(node.neo_id)
        expect(node.labels).to match_array([:two, :three, :four])
      end

      it 'can remove all labels' do
        node = Neo4j::Node.create({}, :one, :two)
        node.set_label
        node = Neo4j::Node.load(node.neo_id)
        expect(node.labels).to eq([])
      end

      it 'does not change labels if there is no change' do
        node = Neo4j::Node.create({}, :one, :two)
        node.set_label(:one, :two)
        expect(node.labels).to match_array([:one, :two])
      end

      it 'can set labels without removing any labels' do
        node = Neo4j::Node.create
        node.set_label(:one, :two)
        node = Neo4j::Node.load(node.neo_id)
        expect(node.labels).to match_array([:one, :two])
      end
    end

    describe 'remove_label' do
      it 'delete given label' do
        node = Neo4j::Node.create({}, :one, :two)
        node.remove_label(:two)
        expect(node.labels).to eq([:one])
      end

      it 'can delete all labels' do
        node = Neo4j::Node.create({}, :one, :two)
        node.remove_label(:two, :one)
        expect(node.labels).to eq([])
      end
    end
  end

  describe 'class methods' do
    describe 'create' do
      it 'creates a label with a name' do
        red = Neo4j::Label.create(@label1)
        expect(red.name).to eq(@label1)
      end
    end


    describe 'find_all_nodes' do
      it 'returns all nodes with that label' do
        result = Neo4j::Label.find_all_nodes(@label1)
        expect(result.count).to eq(2)
        expect(result).to include(@red1, @red2)
      end
    end

    describe 'find_nodes' do
      before(:all) do
        stuff = Neo4j::Label.create(@random_label)
        stuff.drop_index(:colour) # just in case
        stuff.create_index(:colour)
        @red = Neo4j::Node.create({colour: 'red', name: 'r'}, @random_label)
        @green = Neo4j::Node.create({colour: 'green', name: 'g'}, @random_label)
      end

      it 'finds nodes using an index' do
        result = Neo4j::Label.find_nodes(@random_label, :colour, 'red')
        expect(result.count).to eq(1)
        expect(result).to include(@red)
      end


      it 'does not find it if it does not exist' do
        result = Neo4j::Label.find_nodes(@random_label, :colour, 'black')
        expect(result.count).to eq(0)
      end

      it 'does not find it if it does not exist using an unknown label' do
        result = Neo4j::Label.find_nodes(:unknown_label99, :colour, 'red')
        expect(result.count).to eq(0)
      end

      it 'finds it even if there is no index on it' do
        result = Neo4j::Label.find_nodes(@random_label, :name, 'r')
        expect(result).to include(@red)
        expect(result.count).to eq(1)
      end
    end
  end

  describe 'instance methods' do
    describe 'create_index' do
      it 'creates an index on given properties' do
        people = Neo4j::Label.create(:people1)
        people.drop_index(:name, :things)
        people.create_index(:name)
        people.create_index(:things)
        expect(people.indexes[:property_keys].count).to eq(2)
      end
    end

    describe 'indexes' do
      it 'returns which properties is indexed' do
        people = Neo4j::Label.create(:people2)
        people.drop_index(:name1, :name2)
        people.create_index(:name1)
        people.create_index(:name2)
        expect(people.indexes[:property_keys]).to match_array([[:name1], [:name2]])
      end
    end

    describe 'drop_index' do
      it 'drops a index' do
        people = Neo4j::Label.create(:people)
        people.drop_index(:name, :foo)
        people.create_index(:name)
        people.create_index(:foo)
        people.drop_index(:foo)
        expect(people.indexes[:property_keys]).to eq([[:name]])
        people.drop_index(:name)
      end
    end
  end
end
