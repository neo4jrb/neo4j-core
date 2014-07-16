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


  describe 'clause combinations' do
    describe ".match(q: Person).where('q.age > 30')" do
      it_generates "MATCH (q:`Person`) WHERE q.age > 30"
    end

    describe ".where('q.age > 30').match(q: Person)" do
      it_generates "MATCH (q:`Person`) WHERE q.age > 30"
    end

    describe ".where('q.age > 30').start('n').match(q: Person)" do
      it_generates "START n MATCH (q:`Person`) WHERE q.age > 30"
    end

    describe ".match(q: {age: 30}).set(q: {age: 31})" do
      it_generates "MATCH (q {age: 30}) SET q = {age: 31}"
    end

    # WITHS

    describe ".match(q: Person).with('count(q) AS count')" do
      it_generates "MATCH (q:`Person`) WITH count(q) AS count"
    end

    describe ".match(q: Person).with('count(q) AS count').where('count > 2')" do
      it_generates "MATCH (q:`Person`) WITH count(q) AS count WHERE count > 2"
    end

    describe ".match(q: Person).with(count: 'count(q)').where('count > 2').with(new_count: 'count + 5')" do
      it_generates "MATCH (q:`Person`) WITH count(q) AS count WHERE count > 2 WITH count + 5 AS new_count"
    end

    # breaks

    describe ".match(q: Person).match('r:Car').break.match('(p: Person)-->q')" do
      it_generates "MATCH (q:`Person`), r:Car MATCH (p: Person)-->q"
    end

    describe ".match(q: Person).break.match('r:Car').break.match('(p: Person)-->q')" do
      it_generates "MATCH (q:`Person`) MATCH r:Car MATCH (p: Person)-->q"
    end

    describe ".match(q: Person).match('r:Car').break.break.match('(p: Person)-->q')" do
      it_generates "MATCH (q:`Person`), r:Car MATCH (p: Person)-->q"
    end

    # params
  end

  describe 'merging queries' do
    let(:query1) { Neo4j::Core::Query.new.match(p: Person) }
    let(:query2) { Neo4j::Core::Query.new.match(c: :Car) }

    it 'Merging two matches' do
      (query1 & query2).to_cypher.should == 'MATCH (p:`Person`), (c:`Car`)'
    end

    it 'Makes a query that allows further querying' do
      (query1 & query2).match('(p)-[:DRIVES]->(c)').to_cypher.should == 'MATCH (p:`Person`), (c:`Car`), (p)-[:DRIVES]->(c)'
    end

    it 'merges params'

    it 'merges options'
  end

  # START

  describe '#start' do
    describe ".start('r=node:nodes(name = \"Brian\")')" do
      it_generates "START r=node:nodes(name = \"Brian\")"
    end

    describe ".start(r: 'node:nodes(name = \"Brian\")')" do
      it_generates "START r = node:nodes(name = \"Brian\")"
    end
  end

  # MATCH

  describe '#match' do
    it 'is a test!' do
      1.should == 1
    end
    describe ".match('n')" do
      it_generates "MATCH n"
    end

    describe ".match(:n)" do
      it_generates "MATCH n"
    end

    describe ".match(n: Person)" do
      it_generates "MATCH (n:`Person`)"
    end

    describe ".match(n: Note)" do
      it_generates "MATCH (n:`GreatNote`)"
    end

    describe ".match(n: 'Person')" do
      it_generates "MATCH (n:`Person`)"
    end

    describe ".match(n: ':Person')" do
      it_generates "MATCH (n:Person)"
    end

    describe ".match(n: :Person)" do
      it_generates "MATCH (n:`Person`)"
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
      it_generates "MATCH (n:`Person` {name: \"Brian\", age: 33})"
    end

    describe ".match(n: {Person: {name: '{param}'}})" do
      it_generates "MATCH (n:`Person` {name: {param}})"
    end

    describe ".match('n--o')" do
      it_generates "MATCH n--o"
    end

    describe ".match('n--o').match('o--p')" do
      it_generates "MATCH n--o, o--p"
    end
  end

  # OPTIONAL MATCH

  describe '#optional_match' do
    describe ".optional_match(n: Person)" do
      it_generates "OPTIONAL MATCH (n:`Person`)"
    end

    describe ".match('m--n').optional_match('n--o').match('o--p')" do
      it_generates "MATCH m--n, o--p OPTIONAL MATCH n--o"
    end
  end

  # USING

  describe '#using' do
    describe ".using('INDEX m:German(surname)')" do
      it_generates "USING INDEX m:German(surname)"
    end

    describe ".using('SCAN m:German')" do
      it_generates "USING SCAN m:German"
    end

    describe ".using('INDEX m:German(surname)').using('SCAN m:German')" do
      it_generates "USING INDEX m:German(surname) USING SCAN m:German"
    end
  end


  # WHERE

  describe '#where' do
    describe ".where()" do
      it_generates ""
    end

    describe ".where({})" do
      it_generates ""
    end

    describe ".where('q.age > 30')" do
      it_generates "WHERE q.age > 30"
    end

    describe ".where('q.age' => 30)" do
      it_generates "WHERE q.age = 30"
    end

    describe ".where('q.age' => [30, 32, 34])" do
      it_generates "WHERE q.age IN [30, 32, 34]"
    end

    describe ".where(q: {age: [30, 32, 34]})" do
      it_generates "WHERE q.age IN [30, 32, 34]"
    end

    describe ".where('q.age' => nil)" do
      it_generates "WHERE q.age IS NULL"
    end

    describe ".where(q: {age: nil})" do
      it_generates "WHERE q.age IS NULL"
    end

    describe ".where(q: {neo_id: 22})" do
      it_generates "WHERE ID(q) = 22"
    end

    describe ".where(q: {age: 30, name: 'Brian'})" do
      it_generates "WHERE q.age = 30 AND q.name = \"Brian\""
    end

    describe ".where(q: {age: 30, name: 'Brian'}).where('r.grade = 80')" do
      it_generates "WHERE q.age = 30 AND q.name = \"Brian\" AND r.grade = 80"
    end
  end

  # UNWIND

  describe '#unwind' do
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
  end


  # RETURN

  describe '#return' do
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
  end

  # ORDER BY

  describe '#order' do
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

    describe ".order(q: [:age, {name: :desc}])" do
      it_generates "ORDER BY q.age, q.name DESC"
    end

    describe ".order(q: [:age, {name: :desc, grade: :asc}])" do
      it_generates "ORDER BY q.age, q.name DESC, q.grade ASC"
    end
    describe ".order(q: {age: :asc, name: :desc})" do
      it_generates "ORDER BY q.age ASC, q.name DESC"
    end

    describe ".order(q: [:age, 'name desc'])" do
      it_generates "ORDER BY q.age, q.name desc"
    end
  end


  # LIMIT

  describe '#limit' do
    describe ".limit(3)" do
      it_generates "LIMIT 3"
    end

    describe ".limit('3')" do
      it_generates "LIMIT 3"
    end

    describe ".limit(3).limit(5)" do
      it_generates "LIMIT 5"
    end
  end

  # SKIP

  describe '#skip' do
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
  end

  # WITH

  describe '#with' do
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
  end

  # CREATE, CREATE UNIQUE, and MERGE should all work exactly the same

  describe "#create" do
    describe ".create('(:Person)')" do
      it_generates "CREATE (:Person)"
    end

    describe ".create(:Person)" do
      it_generates "CREATE (:Person)"
    end

    describe ".create(age: 41, height: 70)" do
      it_generates "CREATE ( {age: 41, height: 70})"
    end

    describe ".create(Person: {age: 41, height: 70})" do
      it_generates "CREATE (:`Person` {age: 41, height: 70})"
    end

    describe ".create(q: {Person: {age: 41, height: 70}})" do
      it_generates "CREATE (q:`Person` {age: 41, height: 70})"
    end
  end

  describe "#create_unique" do
    describe ".create_unique('(:Person)')" do
      it_generates "CREATE UNIQUE (:Person)"
    end

    describe ".create_unique(:Person)" do
      it_generates "CREATE UNIQUE (:Person)"
    end

    describe ".create_unique(age: 41, height: 70)" do
      it_generates "CREATE UNIQUE ( {age: 41, height: 70})"
    end

    describe ".create_unique(Person: {age: 41, height: 70})" do
      it_generates "CREATE UNIQUE (:`Person` {age: 41, height: 70})"
    end

    describe ".create_unique(q: {Person: {age: 41, height: 70}})" do
      it_generates "CREATE UNIQUE (q:`Person` {age: 41, height: 70})"
    end
  end

  describe "#merge" do
    describe ".merge('(:Person)')" do
      it_generates "MERGE (:Person)"
    end

    describe ".merge(:Person)" do
      it_generates "MERGE (:Person)"
    end

    describe ".merge(age: 41, height: 70)" do
      it_generates "MERGE ( {age: 41, height: 70})"
    end

    describe ".merge(Person: {age: 41, height: 70})" do
      it_generates "MERGE (:`Person` {age: 41, height: 70})"
    end

    describe ".merge(q: {Person: {age: 41, height: 70}})" do
      it_generates "MERGE (q:`Person` {age: 41, height: 70})"
    end
  end


  # DELETE

  describe '#delete' do
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
  end

  # SET

  describe '#set' do
    describe ".set('n = {name: \"Brian\"}')" do
      it_generates "SET n = {name: \"Brian\"}"
    end

    describe ".set(n: {name: 'Brian', age: 30})" do
      it_generates "SET n = {name: \"Brian\", age: 30}"
    end
  end

  describe '#set_props' do
    describe ".set_props('n = {name: \"Brian\"}')" do
      it_generates "SET n = {name: \"Brian\"}"
    end

    describe ".set_props(n: {name: 'Brian', age: 30})" do
      it_generates "SET n.name = \"Brian\", n.age = 30"
    end

    describe ".set_props(n: {name: 'Brian', age: 30}, o: {age: 29})" do
      it_generates "SET n.name = \"Brian\", n.age = 30, o.age = 29"
    end

    describe ".set_props(n: {name: 'Brian', age: 30}).set_props('o.age = 29')" do
      it_generates "SET n.name = \"Brian\", n.age = 30, o.age = 29"
    end
  end

  # ON CREATE and ON MATCH should behave just like set_props
  describe "#on_create_set" do
    describe ".on_create_set('n = {name: \"Brian\"}')" do
      it_generates "ON CREATE SET n = {name: \"Brian\"}"
    end

    describe ".on_create_set(n: {name: 'Brian', age: 30})" do
      it_generates "ON CREATE SET n.name = \"Brian\", n.age = 30"
    end

    describe ".on_create_set(n: {name: 'Brian', age: 30}, o: {age: 29})" do
      it_generates "ON CREATE SET n.name = \"Brian\", n.age = 30, o.age = 29"
    end

    describe ".on_create_set(n: {name: 'Brian', age: 30}).on_create_set('o.age = 29')" do
      it_generates "ON CREATE SET n.name = \"Brian\", n.age = 30, o.age = 29"
    end
  end

  describe "#on_match_set" do
    describe ".on_match_set('n = {name: \"Brian\"}')" do
      it_generates "ON MATCH SET n = {name: \"Brian\"}"
    end

    describe ".on_match_set(n: {name: 'Brian', age: 30})" do
      it_generates "ON MATCH SET n.name = \"Brian\", n.age = 30"
    end

    describe ".on_match_set(n: {name: 'Brian', age: 30}, o: {age: 29})" do
      it_generates "ON MATCH SET n.name = \"Brian\", n.age = 30, o.age = 29"
    end

    describe ".on_match_set(n: {name: 'Brian', age: 30}).on_match_set('o.age = 29')" do
      it_generates "ON MATCH SET n.name = \"Brian\", n.age = 30, o.age = 29"
    end
  end

  # REMOVE

  describe '#remove' do
    describe ".remove('n.prop')" do
      it_generates "REMOVE n.prop"
    end

    describe ".remove('n:American')" do
      it_generates "REMOVE n:American"
    end

    describe ".remove(n: 'prop')" do
      it_generates "REMOVE n.prop"
    end

    describe ".remove(n: :American)" do
      it_generates "REMOVE n:American"
    end

    describe ".remove(n: :American, o: 'prop')" do
      it_generates "REMOVE n:American, o.prop"
    end

    describe ".remove(n: ':prop')" do
      it_generates "REMOVE n:prop"
    end
  end

  # FOREACH



  # UNION

  describe '#union_cypher' do
    it "returns a cypher string with the union of the callee and argument query strings" do
      q = Neo4j::Core::Query.new.match(o: :Person).where(o: {age: 10})
      result = Neo4j::Core::Query.new.match(n: :Person).union_cypher(q)

      result.should == "MATCH (n:`Person`) UNION MATCH (o:`Person`) WHERE o.age = 10"
    end

    it "can represent UNION ALL with an option" do
      q = Neo4j::Core::Query.new.match(o: :Person).where(o: {age: 10})
      result = Neo4j::Core::Query.new.match(n: :Person).union_cypher(q, all: true)

      result.should == "MATCH (n:`Person`) UNION ALL MATCH (o:`Person`) WHERE o.age = 10"
    end

  end


end

