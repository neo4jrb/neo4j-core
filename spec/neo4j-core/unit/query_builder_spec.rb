require 'spec_helper'

describe Neo4j::Core::QueryBuilder do

  def expects_cypher(cypher)
    query = eval("[#{self.class.description}]")
    builder = Neo4j::Core::QueryBuilder.new
    query_hash = builder.to_query_hash(query, :id_to_node)
    builder.to_cypher(query_hash).should == cypher
  end

  def self.it_generates(cypher)
    it "generates #{cypher}" do
      expects_cypher(cypher)
    end
  end

  describe "label: :person, conditions: { name: nil }" do
    it_generates "MATCH (n:`person`) WHERE n.name='' RETURN ID(n)"
  end

  describe 'q: "START n=node(0) RETURN n"'do
    it_generates "START n=node(0) RETURN n"
  end

  describe "label: :person" do
    it_generates "MATCH (n:`person`) RETURN ID(n)"
  end

  describe "label: :person, return: [:name, :age]" do
    it_generates "MATCH (n:`person`) RETURN n.`name` AS `name`,n.`age` AS `age`"
  end

  describe "label: :person, return: 'n.name'" do
    it_generates "MATCH (n:`person`) RETURN n.name"
  end

  describe "label: :person, return: ['n.name', 'n.age']" do
    it_generates "MATCH (n:`person`) RETURN n.name,n.age"
  end

  describe 'label: :person, return: "what ever"' do
    it_generates "MATCH (n:`person`) RETURN what ever"
  end

  describe 'label: {x: :person, y: :cars}, return: "what ever"' do
    it_generates "MATCH (x:`person`),(y:`cars`) RETURN what ever"
  end

  describe "label: :person, match: 'n-[:friends]->o'" do
    it_generates "MATCH (n:`person`),n-[:friends]->o RETURN ID(n)"
  end

  describe "label: :person, match: 'n-[:friends]->o', where: 'o.age=42'" do
    it_generates "MATCH (n:`person`),n-[:friends]->o WHERE o.age=42 RETURN ID(n)"
  end

  describe "label: :person, match: 'n-[:friends]->o', where: ['o.age=42', 'n.age=1']" do
    it_generates "MATCH (n:`person`),n-[:friends]->o WHERE o.age=42 AND n.age=1 RETURN ID(n)"
  end

  describe "label: :person, match: 'n-[:friends]->o'" do
    it_generates "MATCH (n:`person`),n-[:friends]->o RETURN ID(n)"
  end

  describe "label: :person, match: 'n-[:friends]->o', conditions: {age:100}" do
    it_generates "MATCH (n:`person`),n-[:friends]->o WHERE n.age=100 RETURN ID(n)"
  end

  describe "label: :person, conditions: {name:/kalle.*/}" do
    it_generates "MATCH (n:`person`) WHERE n.name=~'kalle.*' RETURN ID(n)"
  end

  describe "label: :person, limit: 50" do
    it_generates "MATCH (n:`person`) RETURN ID(n) LIMIT 50"
  end

  describe "label: :person, limit: 50, skip: 3" do
    it_generates "MATCH (n:`person`) RETURN ID(n) SKIP 3 LIMIT 50"
  end

  describe "label: :person, order: :name" do
    it_generates "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name`"
  end

  describe "label: :person, order: {name: :desc}" do
    it_generates "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name` DESC"
  end

  describe "label: :person, order: [{name: :desc}, :age]" do
    it_generates "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name` DESC, n.`age`"
  end

  describe "label: :person, order: [{name: :desc}, :age], limit: 4, skip: 5" do
    it_generates "MATCH (n:`person`) RETURN ID(n) ORDER BY n.`name` DESC, n.`age` SKIP 5 LIMIT 4"
  end

  describe 'to_map_return_procs' do
    subject do
      Neo4j::Core::QueryBuilder.new
    end

    it 'returns {} for {}' do
      subject.to_map_return_procs({}).should == {}
    end

    describe '{map_return: :node}' do
      it 'returns a proc' do
        subject.to_map_return_procs({map_return: :id_to_node}).should be_kind_of(Proc)
      end

      it 'returns a proc tries to load the id of the first item in the array' do
        expect(Neo4j::Node).to receive(:load).with(42).and_return('a node')
        proc = subject.to_map_return_procs({map_return: :id_to_node})
        proc.call(42).should == 'a node'
      end

    end

  end
end