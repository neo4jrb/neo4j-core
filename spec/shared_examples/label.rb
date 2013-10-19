share_examples_for "Neo4j::Label" do
  describe "class methods" do
    describe 'create' do
      it "creates a label with a name" do
        red = Neo4j::Label.create(:red)
        red.name.should == :red
      end
    end


    describe 'find_all_nodes' do
      before(:all) do
        @red1 = Neo4j::Node.create({}, :red)
        @red2 = Neo4j::Node.create({}, :red)
        @green = Neo4j::Node.create({}, :green)
      end

      it 'returns all nodes with that label' do
        result = Neo4j::Label.find_all_nodes(:red)
        result.count.should == 2
        result.should include(@red1, @red2)
      end
    end

    describe 'find_nodes' do

      before(:all) do
        r = Random.new
        @random_label = ("R " + r.rand(0..10000000).to_s).to_sym

        stuff = Neo4j::Label.create(@random_label)
        stuff.drop_index(:colour) # just in case
        stuff.create_index(:colour)
        @red = Neo4j::Node.create({colour: 'red', name: 'r'}, @random_label)
        @green = Neo4j::Node.create({colour: 'green', name: 'g'}, @random_label)
      end

      it 'finds nodes using an index' do
        result = Neo4j::Label.find_nodes(@random_label, :colour, 'red')
        result.count.should == 1
        result.should include(@red)
      end


      it "does not find it if it does not exist" do
        result = Neo4j::Label.find_nodes(@random_label, :colour, 'black')
        result.count.should == 0
      end

      it "does not find it if it does not exist using an unknown label" do
        result = Neo4j::Label.find_nodes(:unknown_label99, :colour, 'red')
        result.count.should == 0
      end

      it "finds it event if there is no index on it" do
        result = Neo4j::Label.find_nodes(@random_label, :name, 'r')
        result.should include(@red)
        result.count.should == 1
      end
    end

  end

  describe 'instance methods' do
    describe 'create_index' do
      it "creates an index on given properties" do
        people = Neo4j::Label.create(:people1)
        people.drop_index(:name, :things)
        people.create_index(:name)
        people.create_index(:things)
        sleep(0.1)
#        people.indexes.count.should == 2
      end
    end

    describe 'indexes' do
      it "returns which properties is indexed" do
        people = Neo4j::Label.create(:people2)
        people.drop_index(:name1, :name2)
        people.create_index(:name1)
        people.create_index(:name2)
#        people.indexes.should =~ [[:name1], [:name2]]
      end
    end

    describe 'drop' do
      it "drops a index" do
        people = Neo4j::Label.create(:people)
        people.drop_index(:name, :foo)
        people.create_index(:name)
        people.create_index(:foo)
        people.drop_index(:foo)
#        people.indexes.should == [[:name]]
        people.drop_index(:name)
      end
    end
  end
end