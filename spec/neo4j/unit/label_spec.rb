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
    # Neo4j::Label.query(:person, matches: 'n-[friends]->o', where)

    describe 'query' do
      let(:session) do
        double('mock session', query_default_return: ' RETURN ID(n)', search_result_to_enumerable: nil)
      end

      before do
        Neo4j::Session.stub(:current){ session }
      end

      def expects_cypher(cypher)
        session.should_receive(:_query_or_fail).with(cypher)
        query = eval(self.class.description);
        Neo4j::Label.query(*query)
      end

      def self.it_generates(cypher)
        it "generates #{cypher}" do
          expects_cypher(cypher)
        end
      end

      describe "[:person, matches: 'n-[:friends]->o']" do
        it_generates "MATCH (n:`person`),n-[:friends]->o RETURN ID(n)"
      end

      describe "[:person, matches: 'n-[:friends]->o', conditions: {age:100}]" do
        it_generates "MATCH (n:`person`),n-[:friends]->o WHERE n.age=100 RETURN ID(n)"
      end

      describe ":person, where: 'n.age=42'" do
        it 'generates correct cypher'
      end

      describe ':person, limit ...'

      describe ":person, as: x, where: 'x.age=42'" do
        # avoid hard coding the magical n symbol
        it 'generates correct cypher' do
          pending 'generates MATCH (x:`person`) WHERE x.age=42 RETURN ID(x)'
        end
      end

      describe "[:person, matches: ['n-[:friends]->o','n--m']]" do
        it_generates "MATCH (n:`person`),n-[:friends]->o,n--m RETURN ID(n)"
      end

    end

  end

end


