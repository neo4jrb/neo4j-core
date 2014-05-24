require 'spec_helper'

describe Neo4j::Label do

  describe 'instance methods' do
    let(:session) do
      double(:session)
    end

    let(:label) do
      label = Neo4j::Label.new
      label.stub(:name) { :person }
      label
    end

    describe 'create_constraint' do
      it 'generates a cypher query' do
        session.should_receive(:_query_or_fail).with("CREATE CONSTRAINT ON (n:`person`) ASSERT n.`name` IS UNIQUE")
        label.create_constraint(:name, {type: :unique}, session)
      end

      it 'raise an exception if invalid constraint' do
        expect{ label.create_constraint(:name, type: :unknown)}.to raise_error
      end
    end

    describe '#drop_constraint' do
      it 'generates a cypher query' do
        session.should_receive(:_query_or_fail).with("DROP CONSTRAINT ON (n:`person`) ASSERT n.`name` IS UNIQUE")
        label.drop_constraint(:name, {type: :unique}, session)
      end

      it 'raise an exception if invalid constraint' do
        expect{ label.drop_constraint(:name, type: :unknown)}.to raise_error
      end

    end
  end


  describe 'class methods' do
    # Exampel
    # Neo4j::Label.query(:person, match: 'n-[friends]->o', where)

    describe 'query' do
      let(:session) do
        double('mock session', search_result_to_enumerable: nil).tap do |obj|
          obj.stub(:query_default_return) {|as| " RETURN ID(#{as})"}
        end
      end

      before do
        Neo4j::Session.stub(:current){ session }
      end

      def expects_cypher(cypher)
        session.should_receive(:_query_or_fail).with(cypher)
        query = eval("[#{self.class.description}]");
        Neo4j::Label.query(*query)
      end

      def self.it_generates(cypher)
        it "generates #{cypher}" do
          expects_cypher(cypher)
        end
      end

      describe ":person, as: :x, match: 'x-[:friends]->o'" do
        it_generates "MATCH (x:`person`),x-[:friends]->o RETURN ID(x)"
      end

      describe ":person, match: 'n-[:friends]->o', where: 'o.age=42'" do
        it_generates "MATCH (n:`person`),n-[:friends]->o WHERE o.age=42 RETURN ID(n)"
      end

      describe ":person, match: 'n-[:friends]->o', where: ['o.age=42', 'n.age=1']" do
        it_generates "MATCH (n:`person`),n-[:friends]->o WHERE o.age=42 AND n.age=1 RETURN ID(n)"
      end

      describe ":person, as: :x, match: 'x-[:friends]->o', where: 'x.age=42'" do
        it_generates "MATCH (x:`person`),x-[:friends]->o WHERE x.age=42 RETURN ID(x)"
      end

      describe ":person, match: 'n-[:friends]->o'" do
        it_generates "MATCH (n:`person`),n-[:friends]->o RETURN ID(n)"
      end

      describe ":person, match: 'n-[:friends]->o', conditions: {age:100}" do
        it_generates "MATCH (n:`person`),n-[:friends]->o WHERE n.age=100 RETURN ID(n)"
      end

      describe ":person, match: ['n-[:friends]->o','n--m']" do
        it_generates "MATCH (n:`person`),n-[:friends]->o,n--m RETURN ID(n)"
      end

      describe ":person, limit: 50" do
        it_generates "MATCH (n:`person`) RETURN ID(n) LIMIT 50"
      end

      describe ":person, as: :foo, limit: 50" do
        # silly but possible
        it_generates "MATCH (foo:`person`) RETURN ID(foo) LIMIT 50"
      end

      describe ":person, order: :name" do
        it_generates "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name`"
      end

      describe ":person, order: {name: :desc}" do
        it_generates "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name` DESC"
      end

      describe ":person, order: [{name: :desc}, :age]" do
        it_generates "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name` DESC, n.`age`"
      end

      describe ":person, conditions: {name: 'jimmy', age: 42}" do
        it_generates "MATCH (n:`person`) WHERE n.name='jimmy' AND n.age=42 RETURN ID(n)"
      end

      describe ":person, conditions: {name: 'jimmy', age: 42}" do
        it_generates "MATCH (n:`person`) WHERE n.name='jimmy' AND n.age=42 RETURN ID(n)"
      end

      describe ':person, return: "what ever"' do
        it_generates "MATCH (n:`person`) RETURN what ever"
      end

      describe ':person, return: :name' do
        it_generates "MATCH (n:`person`) RETURN n.`name`"
      end

      describe ':person, return: [:name,:age]' do
        it_generates "MATCH (n:`person`) RETURN n.`name`,n.`age`"
      end

      describe ':person, return: [:name,:age]' do
        it_generates "MATCH (n:`person`) RETURN n.`name`,n.`age`"
      end

      describe ':person, match: "n--o", return: {count: :o}' do
        # TODO
        #it_generates "MATCH (n:`person`), n--o RETURN count(o)"
      end

      describe ':person, match: "n--o", return: {node: :o}]' do
        # TODO
        # column o should be wrapped as nodes, need another test for this
        #it_generates "MATCH (n:`person`), n--o RETURN ID(o)"
      end

      describe ':person, match: "n--o", return: [:n, {node: :o}]' do
        # TODO
        # {node: :o} says that the result column o should be wrap as nodes
        #it_generates "MATCH (n:`person`) RETURN ID(n), ID(o)"
      end

    end

  end

end


