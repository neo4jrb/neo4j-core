require 'spec_helper'

describe Neo4j::Core::Query do

  def expects_cypher(cypher)
    query = eval("Neo4j::Core::Query.new#{self.class.description}")
    query.to_cypher.should == cypher
  end

  def self.it_generates(cypher)
    it "generates #{cypher}" do
      expects_cypher(cypher)
    end
  end

  describe ".match('n')"do
    it_generates "MATCH n"
  end

  describe ".match(:n)"do
    it_generates "MATCH n"
  end

  describe ".match(n: 'Person')"do
    it_generates "MATCH n:Person"
  end

  describe ".match(n: 'Person {name: \"Brian\"}')"do
    it_generates "MATCH n:Person {name: \"Brian\"}"
  end

  describe ".match(n: {Person: {name: 'Brian', age: 33}})"do
    it_generates "MATCH n:Person {name: \"Brian\", age: 33}"
  end

  describe ".match(n: {name: 'Brian', age: 33})"do
    it_generates "MATCH n {name: \"Brian\", age: 33}"
  end

  describe ".match('n--o')"do
    it_generates "MATCH n--o"
  end

  describe ".match('n--o').match('o--p')"do
    it_generates "MATCH n--o, o--p"
  end


end

