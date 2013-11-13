share_examples_for "Neo4j::Label" do

  before(:all) do
    r = Random.new
    @label1 = ("R1 " + r.rand(0..1000000).to_s).to_sym
    @label2 = ("R2 " + r.rand(0..1000000).to_s).to_sym
    @random_label = ("R3 " + r.rand(0..1000000).to_s).to_sym
    @red1 = Neo4j::Node.create({}, @label1)
    @red2 = Neo4j::Node.create({}, @label1)
    @green = Neo4j::Node.create({}, @label2)
  end


  describe "class methods" do
    describe 'create' do
      it "creates a label with a name" do
        red = Neo4j::Label.create(@label1)
        red.name.should == @label1
      end
    end


    describe 'find_all_nodes' do
      it 'returns all nodes with that label' do
        result = Neo4j::Label.find_all_nodes(@label1)
        result.count.should == 2
        result.should include(@red1, @red2)
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

      it "finds it even if there is no index on it" do
        result = Neo4j::Label.find_nodes(@random_label, :name, 'r')
        result.should include(@red)
        result.count.should == 1
      end
    end

    describe 'query' do
      before(:all) do
        r = Random.new
        @label = ("R3" + r.rand(0..1000000).to_s).to_sym
        @kalle = Neo4j::Node.create({name: 'kalle', age: 4}, @label)
        @andreas2 = Neo4j::Node.create({name: 'andreas', age: 2}, @label)
        @andreas1 = Neo4j::Node.create({name: 'andreas', age: 1}, @label)
        @zebbe = Neo4j::Node.create({name: 'zebbe', age: 3}, @label)
      end

      describe 'finds with :conditions' do
        it 'finds all nodes matching condition' do
          result = Neo4j::Label.query(@label, conditions: {name: 'andreas'})
          result.should include(@andreas1, @andreas2)
          result.count.should == 2
        end

        it 'returns all nodes if no conditions' do
          result = Neo4j::Label.query(@label, {})
          result.should include(@kalle, @andreas2, @andreas1, @zebbe)
          result.count.should == 4

          result = Neo4j::Label.query(@label, conditions: {})
          result.should include(@kalle, @andreas2, @andreas1, @zebbe)
          result.count.should == 4
        end

        it 'returns a empty enumerable if not match condition' do
          Neo4j::Label.query(@label, conditions: {name: 'andreas42'}).count.should == 0
          Neo4j::Label.query(@label, conditions: {namqe: 'andreas'}).count.should == 0
        end

        #it 'does a greater than query for .gt keys' do
        #  pending
        #  # Not sure about this query syntax using a Hash, but this is a bit similar to mongoid API
        #  # Maybe it was better like it was in the old neo4j-core API with a fluent API instead
        #  result = Neo4j::Label.query(@label, conditions: {:age => {gt: 18, lt: 4}})
        #end
      end

      describe 'sort' do
        it 'sorts with: order: :name' do
          result = Neo4j::Label.query(@label, order: :name)
          result.count.should == 4
          result.to_a.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
        end

        it 'sorts with: order: [:name, :age]' do
          result = Neo4j::Label.query(@label, order: [:name, :age])
          result.count.should == 4
          result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
          result.map{|n| n[:age]}.should == [1,2,4,3]
        end

        it 'sorts with: order: [:name, :age]' do
          result = Neo4j::Label.query(@label, order: [:name, :age])
          result.count.should == 4
          result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
          result.map{|n| n[:age]}.should == [1,2,4,3]
        end

        it 'sorts with order: {name: :desc}' do
          result = Neo4j::Label.query(@label, order: {name: :desc})
          result.map{|n| n[:name]}.should == %w[zebbe kalle andreas andreas]

          result = Neo4j::Label.query(@label, order: {name: :asc})
          result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
        end

        it 'sorts with order: [:name, {age: :desc}]' do
          result = Neo4j::Label.query(@label, order: [:name, {age: :desc}])
          result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
          result.map{|n| n[:age]}.should == [2,1,4,3]

          result = Neo4j::Label.query(@label, order: [:name, {age: :asc}])
          result.map{|n| n[:name]}.should == %w[andreas andreas kalle zebbe]
          result.map{|n| n[:age]}.should == [1,2,4,3]
        end

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
        people.indexes[:property_keys].count.should == 2
      end
    end

    describe 'indexes' do
      it "returns which properties is indexed" do
        people = Neo4j::Label.create(:people2)
        people.drop_index(:name1, :name2)
        people.create_index(:name1)
        people.create_index(:name2)
        people.indexes[:property_keys].should =~ [[:name1], [:name2]]
      end
    end

    describe 'drop_index' do
      it "drops a index" do
        people = Neo4j::Label.create(:people)
        people.drop_index(:name, :foo)
        people.create_index(:name)
        people.create_index(:foo)
        people.drop_index(:foo)
        people.indexes[:property_keys].should == [[:name]]
        people.drop_index(:name)
      end
    end
  end
end