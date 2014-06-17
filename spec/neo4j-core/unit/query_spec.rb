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

  # OPTIONAL MATCH

  describe ".optional_match(n: Person)" do
    it_generates "OPTIONAL MATCH (n:Person)"
  end

  describe ".match('m--n').optional_match('n--o').match('o--p')" do
    it_generates "MATCH m--n, o--p OPTIONAL MATCH n--o"
  end

  # USING

  describe ".using('INDEX m:German(surname)')" do
    it_generates "USING INDEX m:German(surname)"
  end

  describe ".using('SCAN m:German')" do
    it_generates "USING SCAN m:German"
  end

  describe ".using('INDEX m:German(surname)').using('SCAN m:German')" do
    it_generates "USING INDEX m:German(surname) USING SCAN m:German"
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

  # UNWIND

  describe ".unwind('val AS x')" do
    it_generates "UNWIND val AS x"
  end

  describe ".unwind(x: :val)" do
    it_generates "UNWIND val AS x"
  end

  describe ".unwind(x: 'val')" do
    it_generates "UNWIND val AS x"
  end

  describe ".unwind(x: [1,3,5])" do
    it_generates "UNWIND [1, 3, 5] AS x"
  end

  describe ".unwind(x: [1,3,5]).unwind('val as y')" do
    it_generates "UNWIND [1, 3, 5] AS x UNWIND val as y"
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

  # ORDER BY

  describe ".order('q.name')" do
    it_generates "ORDER BY q.name"
  end

  describe ".order_by('q.name')" do
    it_generates "ORDER BY q.name"
  end

  describe ".order('q.age', 'q.name DESC')" do
    it_generates "ORDER BY q.age, q.name DESC"
  end

  describe ".order(q: :age)" do
    it_generates "ORDER BY q.age"
  end

  describe ".order(q: {age: :asc, name: :desc})" do
    it_generates "ORDER BY q.age ASC, q.name DESC"
  end

  describe ".order(q: [:age, 'name desc'])" do
    it_generates "ORDER BY q.age, q.name desc"
  end


  # LIMIT

  describe ".limit(3)" do
    it_generates "LIMIT 3"
  end

  describe ".limit('3')" do
    it_generates "LIMIT 3"
  end

  describe ".limit(3).limit(5)" do
    it_generates "LIMIT 5"
  end

  # SKIP

  describe ".skip(5)" do
    it_generates "SKIP 5"
  end

  describe ".skip('5')" do
    it_generates "SKIP 5"
  end

  describe ".skip(5).skip(10)" do
    it_generates "SKIP 10"
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

  # CREATE, CREATE UNIQUE, and MERGE

  {
    create: 'CREATE',
    create_unique: 'CREATE UNIQUE',
    merge: 'MERGE'
  }.each do |method, clause|
    describe ".#{method}(':Person')" do
      it_generates "#{clause} (:Person)"
    end

    describe ".#{method}(age: 41, height: 70)" do
      it_generates "#{clause} ( {age: 41, height: 70})"
    end

    describe ".#{method}(Person: {age: 41, height: 70})" do
      it_generates "#{clause} (:Person {age: 41, height: 70})"
    end

    describe ".#{method}(q: {Person: {age: 41, height: 70}})" do
      it_generates "#{clause} (q:Person {age: 41, height: 70})"
    end
  end

  # DELETE

  describe ".delete('n')" do
    it_generates "DELETE n"
  end

  describe ".delete(:n)" do
    it_generates "DELETE n"
  end

  describe ".delete('n', :o)" do
    it_generates "DELETE n, o"
  end

  describe ".delete(['n', :o])" do
    it_generates "DELETE n, o"
  end

  # SET

  describe ".set('n = {name: \"Brian\"}')" do
    it_generates "SET n = {name: \"Brian\"}"
  end

  describe ".set(n: {name: 'Brian', age: 30})" do
    it_generates "SET n = {name: \"Brian\", age: 30}"
  end

  describe ".set_props(n: {name: 'Brian', age: 30})" do
    it_generates "SET n.name = \"Brian\", n.age = 30"
  end

  # REMOVE

  # FOREACH ?

  # UNION




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

  describe ".match(q: {age: 30}).set(q: {age: 31})" do
    it_generates "MATCH (q {age: 30}) SET q = {age: 31}"
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

