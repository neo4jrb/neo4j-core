require 'spec_helper'

describe Neo4j::Core::Query do

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
    it_generates "MATCH n:Person"
  end

  describe ".match(n: Note)" do
    it_generates "MATCH n:GreatNote"
  end

  describe ".match(n: 'Person')" do
    it_generates "MATCH n:Person"
  end

  describe ".match(n: 'Person {name: \"Brian\"}')" do
    it_generates "MATCH n:Person {name: \"Brian\"}"
  end

  describe ".match(n: {Person: {name: 'Brian', age: 33}})" do
    it_generates "MATCH n:Person {name: \"Brian\", age: 33}"
  end

  describe ".match(n: {name: 'Brian', age: 33})" do
    it_generates "MATCH n {name: \"Brian\", age: 33}"
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



  # COMBINATIONS
  describe ".match(q: Person).where('q.age > 30')" do
    it_generates "MATCH q:Person WHERE q.age > 30"
  end

  describe ".where('q.age > 30').match(q: Person)" do
    it_generates "MATCH q:Person WHERE q.age > 30"
  end


end

