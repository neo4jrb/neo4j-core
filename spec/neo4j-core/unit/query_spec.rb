require 'spec_helper'

describe Neo4j::Core::Query do

  describe 'options' do
    let(:query) { Neo4j::Core::Query.new(parser: 2.0) }

    it 'should generate a per-query cypher parser version' do
      query.to_cypher.should == 'CYPHER 2.0'
    end

    describe 'subsequent call' do
      let(:query) { super().match('q:Person') }

      it 'should combine the parser version with the rest of the query' do
        query.to_cypher.should == 'CYPHER 2.0 MATCH q:Person'
      end
    end
  end

  class Person
  end

  class Note
    CYPHER_LABEL = 'GreatNote' 
  end

  def expects_cypher(cypher)
    query = eval("Neo4j::Core::Query.new#{self.class.description}")
    query.to_cypher.should == cypher
  end

  def self.it_generates(cypher)
    it "generates #{cypher}" do
      expects_cypher(cypher)
    end
  end

  # START

  describe ".start('r=node:nodes(name = \"Brian\")')" do
    it_generates "START r=node:nodes(name = \"Brian\")"
  end

  describe ".start(r: 'node:nodes(name = \"Brian\")')" do
    it_generates "START r = node:nodes(name = \"Brian\")"
  end


  # MATCH

  describe ".match('n')" do
    it_generates "MATCH n"
  end

  describe ".match(:n)" do
    it_generates "MATCH n"
  end

  describe ".match(n: Person)" do
    it_generates "MATCH (n:Person)"
  end

  describe ".match(n: Note)" do
    it_generates "MATCH (n:GreatNote)"
  end

  describe ".match(n: 'Person')" do
    it_generates "MATCH (n:Person)"
  end

  describe ".match(n: ':Person')" do
    it_generates "MATCH (n:Person)"
  end

  describe ".match(n: ' :Person')" do
    it_generates "MATCH (n:Person)"
  end

  describe ".match(n: 'Person {name: \"Brian\"}')" do
    it_generates "MATCH (n:Person {name: \"Brian\"})"
  end

  describe ".match(n: {name: 'Brian', age: 33})" do
    it_generates "MATCH (n {name: \"Brian\", age: 33})"
  end

  describe ".match(n: {Person: {name: 'Brian', age: 33}})" do
    it_generates "MATCH (n:Person {name: \"Brian\", age: 33})"
  end

  describe ".match('n--o')" do
    it_generates "MATCH n--o"
  end

  describe ".match('n--o').match('o--p')" do
    it_generates "MATCH n--o, o--p"
  end

  # WHERE

  describe ".where('q.age > 30')" do
    it_generates "WHERE q.age > 30"
  end

  describe ".where('q.age' => 30)" do
    it_generates "WHERE q.age = 30"
  end

  describe ".where(q: {age: 30, name: 'Brian'})" do
    it_generates "WHERE q.age = 30 AND q.name = \"Brian\""
  end

  describe ".where(q: {age: 30, name: 'Brian'}).where('r.grade = 80')" do
    it_generates "WHERE q.age = 30 AND q.name = \"Brian\" AND r.grade = 80"
  end

  # RETURN

  describe ".return('q')" do
    it_generates "RETURN q"
  end

  describe ".return(:q)" do
    it_generates "RETURN q"
  end

  describe ".return('q.name, q.age')" do
    it_generates "RETURN q.name, q.age"
  end

  describe ".return(q: [:name, :age], r: :grade)" do
    it_generates "RETURN q.name, q.age, r.grade"
  end

  # LIMIT

  describe ".limit(3)" do
    it_generates "LIMIT 3"
  end

  describe ".limit('3')" do
    it_generates "LIMIT 3"
  end

  # SKIP

  describe ".skip(5)" do
    it_generates "SKIP 5"
  end

  describe ".skip('5')" do
    it_generates "SKIP 5"
  end

  describe ".offset(6)" do
    it_generates "SKIP 6"
  end

  # WITH

  describe ".with('n.age AS age')" do
    it_generates "WITH n.age AS age"
  end

  describe ".with('n.age AS age', 'count(n) as c')" do
    it_generates "WITH n.age AS age, count(n) as c"
  end

  describe ".with(['n.age AS age', 'count(n) as c'])" do
    it_generates "WITH n.age AS age, count(n) as c"
  end

  describe ".with(age: 'n.age')" do
    it_generates "WITH n.age AS age"
  end

  # CREATE

  describe ".create(':Person')" do
    it_generates "CREATE (:Person)"
  end

  describe ".create(age: 41, height: 70)" do
    it_generates "CREATE ( {age: 41, height: 70})"
  end

  describe ".create(Person: {age: 41, height: 70})" do
    it_generates "CREATE (:Person {age: 41, height: 70})"
  end

  describe ".create(q: {Person: {age: 41, height: 70}})" do
    it_generates "CREATE (q:Person {age: 41, height: 70})"
  end

  # COMBINATIONS
  describe ".match(q: Person).where('q.age > 30')" do
    it_generates "MATCH (q:Person) WHERE q.age > 30"
  end

  describe ".where('q.age > 30').match(q: Person)" do
    it_generates "MATCH (q:Person) WHERE q.age > 30"
  end

  describe ".where('q.age > 30').start('n').match(q: Person)" do
    it_generates "START n MATCH (q:Person) WHERE q.age > 30"
  end

  # WITHS

  describe ".match(q: Person).with('count(q) AS count')" do
    it_generates "MATCH (q:Person) WITH count(q) AS count"
  end

  describe ".match(q: Person).with('count(q) AS count').where('count > 2')" do
    it_generates "MATCH (q:Person) WITH count(q) AS count WHERE count > 2"
  end

  describe ".match(q: Person).with(count: 'count(q)').where('count > 2').with(new_count: 'count + 5')" do
    it_generates "MATCH (q:Person) WITH count(q) AS count WHERE count > 2 WITH count + 5 AS new_count"
  end

end

