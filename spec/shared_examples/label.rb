share_examples_for "Neo4j::Label" do
  describe "class methods" do
    describe 'create' do
      it "creates a label with a name" do
        red = Neo4j::Label.create(:red)
        red.name.should == :red
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

    describe 'find_nodes' do
      it 'find can find all nodes for a label' do
        stuff = Neo4j::Label.create(:stuff)
        red = Neo4j::Node.create({colour: 'red'}, :stuff)
        green = Neo4j::Node.create({colour: 'green'}, :stuff)

        result = stuff.find_nodes
        result.count.should == 2
        result.should include(red, green)
      end

      it 'find can find nodes using an index' do
        stuff = Neo4j::Label.create(:stuff2)
        stuff.drop_index(:colour) # just in case
        stuff.create_index(:colour)
        red = Neo4j::Node.create({colour: 'red'}, :stuff2)
        green = Neo4j::Node.create({colour: 'green'}, :stuff2)

        result = stuff.find_nodes(:colour, 'red')
        result.count.should == 1
        result.should include(red)
      end


      it "does not find it if it does not exist" do
        stuff = Neo4j::Label.create(:stuff3)
        stuff.drop_index(:colour) # just in case
        stuff.create_index(:colour)
        result = stuff.find_nodes(:colour, 'red')
        result.count.should == 0
      end

      it "can find nodes without index" do
        pending "server and embedded get different results"
        stuff = Neo4j::Label.create(:stuff4)
        stuff.drop_index(:colour) # just in case
        red = Neo4j::Node.create({colour: 'red'}, :stuff4)
        result = stuff.find_nodes(:colour, 'red')
        result.should include(red)
      end
    end
  end
end