require 'spec_helper'

class FooIndex
  extend Neo4j::Core::Index::ClassMethods
  include Neo4j::Core::Index

  self.node_indexer do
    index_names :exact => 'fooindex_exact', :fulltext => 'fooindex_fulltext'
    trigger_on :myindex => true
  end

  index :name
  index :desc, :type => :fulltext
end


describe "Neo4j::Cypher" do

  describe "DSL   { node(3) }" do
    it { Proc.new { node(3) }.should be_cypher("START n0=node(3) RETURN n0") }
  end

  describe "DSL   { node(3,4) }" do
    it { Proc.new { node(3, 4) }.should be_cypher("START n0=node(3,4) RETURN n0") }
  end

  describe "DSL   { rel(3) }" do
    it { Proc.new { rel(3) }.should be_cypher("START r0=relationship(3) RETURN r0") }
  end

  describe "DSL   { start n = node(3); match n <=> :x; ret :x }" do
    it { Proc.new { start n = node(3); match n <=> :x; ret :x }.should be_cypher("START n0=node(3) MATCH (n0)--(x) RETURN x") }
  end


  describe "DSL   { x = node; n = node(3); match n <=> x; ret x }" do
    it { Proc.new { x = node; n = node(3); match n <=> x; ret x }.should be_cypher("START n0=node(3) MATCH (n0)--(v0) RETURN v0") }
  end

  describe "DSL   { x = node; n = node(3); match n <=> x; ret x[:name] }" do
    it { Proc.new { x = node; n = node(3); match n <=> x; ret x[:name] }.should be_cypher("START n0=node(3) MATCH (n0)--(v0) RETURN v0.name") }
  end


  describe "DSL   { n = node(3).as(:n); n <=> node.as(:x); :x }" do
    it { Proc.new { n = node(3).as(:n); n <=> node.as(:x); :x }.should be_cypher("START n=node(3) MATCH (n)--(x) RETURN x") }
  end


  describe "DSL   { node(3) <=> node(:x); :x }" do
    it { Proc.new { node(3) <=> node(:x); :x }.should be_cypher("START n0=node(3) MATCH (n0)--(x) RETURN x") }
  end

  describe "DSL   { node(3) <=> 'foo'; :foo }" do
    it { Proc.new { node(3) <=> 'foo'; :foo }.should be_cypher("START n0=node(3) MATCH (n0)--(foo) RETURN foo") }
  end

  describe "DSL   { r = rel(0); ret r }" do
    it { Proc.new { r = rel(0); ret r }.should be_cypher("START r0=relationship(0) RETURN r0") }
  end

  describe "DSL   { n = node(1, 2, 3); ret n }" do
    it { Proc.new { n = node(1, 2, 3); ret n }.should be_cypher("START n0=node(1,2,3) RETURN n0") }
  end

  describe %q[DSL   query(FooIndex, "name:A")] do
    it { Proc.new { query(FooIndex, "name:A") }.should be_cypher(%q[START n0=node:fooindex_exact(name:A) RETURN n0]) }
  end

  describe %q[DSL   query(FooIndex, "name:A", :fulltext)] do
    it { Proc.new { query(FooIndex, "name:A", :fulltext) }.should be_cypher(%q[START n0=node:fooindex_fulltext(name:A) RETURN n0]) }
  end

  describe %q[DSL   lookup(FooIndex, "name", "A")] do
    it { Proc.new { lookup(FooIndex, "name", "A") }.should be_cypher(%q[START n0=node:fooindex_exact(name="A") RETURN n0]) }
  end

  describe %q[DSL   lookup(FooIndex, "desc", "A")] do
    it { Proc.new { lookup(FooIndex, "desc", "A") }.should be_cypher(%q[START n0=node:fooindex_fulltext(desc="A") RETURN n0]) }
  end

  describe "DSL   { a = node(1); b=node(2); ret(a, b) }" do
    it { Proc.new { a = node(1); b=node(2); ret(a, b) }.should be_cypher(%q[START n0=node(1),n1=node(2) RETURN n0,n1]) }
  end

  describe "DSL   { [node(1), node(2)] }" do
    it { Proc.new { [node(1), node(2)] }.should be_cypher(%q[START n0=node(1),n1=node(2) RETURN n0,n1]) }
  end

  describe "DSL   { node(3) >> :x; :x }" do
    it { Proc.new { node(3) >> :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)-->(x) RETURN x") }
  end

  describe "DSL   { node(3) >> node(:c) >> :d; :c }" do
    it { Proc.new { node(3) >> node(:c) >> :d; :c }.should be_cypher(%{START n0=node(3) MATCH (n0)-->(c)-->(d) RETURN c}) }
  end

  describe "DSL   { node(3) << :x; :x }" do
    it { Proc.new { node(3) << :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)<--(x) RETURN x") }
  end

  describe "DSL   { node(3) << node(:c) << :d; :c }" do
    it { Proc.new { node(3) << node(:c) << :d; :c }.should be_cypher(%{START n0=node(3) MATCH (n0)<--(c)<--(d) RETURN c}) }
  end

  describe "DSL   { node(3) > :r > :x; :r }" do
    it { Proc.new { node(3) > :r > :x; :r }.should be_cypher("START n0=node(3) MATCH (n0)-[r]->(x) RETURN r") }
  end

  describe "DSL   { node(3) << node(:c) < ':friends' < :d; :d }" do
    it { Proc.new { node(3) << node(:c) < ':friends' < :d; :d }.should be_cypher(%{START n0=node(3) MATCH (n0)<--(c)<-[:friends]-(d) RETURN d}) }
  end

  describe "DSL   { (node(3) << node(:c)) - ':friends' - :d; :d }" do
    it { Proc.new { (node(3) << node(:c)) - ':friends' - :d; :d }.should be_cypher(%{START n0=node(3) MATCH (n0)<--(c)-[:friends]-(d) RETURN d}) }
  end

  describe "DSL   { node(3) << node(:c) > ':friends' > :d; :d }" do
    it { Proc.new { node(3) << node(:c) > ':friends' > :d; :d }.should be_cypher(%{START n0=node(3) MATCH (n0)<--(c)-[:friends]->(d) RETURN d}) }
  end

  describe "DSL   { node(3) > 'r:friends' > :x; :r }" do
    it { Proc.new { node(3) > 'r:friends' > :x; :r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
  end

  describe "DSL   { r = rel('r:friends').as(:r); node(3) > r > :x; r }" do
    it { Proc.new { r = rel('r:friends').as(:r); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
  end

  describe "DSL   { r = rel('r:friends'); node(3) > r > :x; r }" do
    it { Proc.new { r = rel('r:friends'); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
  end

  describe "DSL   { r = rel('r?:friends'); node(3) > r > :x; r }" do
    it { Proc.new { r = rel('r?:friends'); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r?:friends]->(x) RETURN r") }
  end

  describe "DSL   { node(3) > rel('?') > :x; :x }" do
    it { Proc.new { node(3) > rel('?') > :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)-[?]->(x) RETURN x") }
  end

  describe "DSL   { node(3) > rel('r?') > :x; :x }" do
    it { Proc.new { node(3) > rel('r?') > :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)-[r?]->(x) RETURN x") }
  end

  describe "DSL   { node(3) > rel('r?') > 'bla'; :x }" do
    it { Proc.new { node(3) > rel('r?') > 'bla'; :x }.should be_cypher("START n0=node(3) MATCH (n0)-[r?]->(bla) RETURN x") }
  end

  describe "DSL   { node(3) > ':r' > 'bla'; :x }" do
    it { Proc.new { node(3) > ':r' > 'bla'; :x }.should be_cypher("START n0=node(3) MATCH (n0)-[:r]->(bla) RETURN x") }
  end

  describe "DSL   { node(3) > :r > node; node }" do
    it { Proc.new { node(3) > :r > node; :r }.should be_cypher("START n0=node(3) MATCH (n0)-[r]->(v0) RETURN r") }
  end

  describe "DSL   { r=rel('?'); node(3) > r > :x; r }" do
    it do
      pending "this should raise an error since it's an illegal cypher query"
      Proc.new { r=rel('?'); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r?]->(x) RETURN x")
    end
  end

  describe %{n=node(3,1).as(:n); where(%q[n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias"')]} do
    it { Proc.new { n=node(3, 1).as(:n); where(%q[(n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias")]); ret n }.should be_cypher(%q[START n=node(3,1) WHERE (n.age < 30 and n.name = "Tobias") or not(n.name = "Tobias") RETURN n]) }
  end

  describe %{n=node(3,1); where n[:age] < 30; ret n} do
    it { Proc.new { n=node(3, 1); where n[:age] < 30; ret n }.should be_cypher(%q[START n0=node(3,1) WHERE n0.age < 30 RETURN n0]) }
  end

  describe %{n=node(3, 1); where (n[:name] == 'foo').not; ret n} do
    it { Proc.new { n=node(3, 1); where (n[:name] == 'foo').not; ret n }.should be_cypher(%q[START n0=node(3,1) WHERE not(n0.name = "foo") RETURN n0]) }
  end

  describe %{r=rel(3,1); where r[:since] < 2; r} do
    it { Proc.new { r=rel(3, 1); where r[:since] < 2; r }.should be_cypher(%q[START r0=relationship(3,1) WHERE r0.since < 2 RETURN r0]) }
  end

  describe %{r=rel('r?'); n=node(2); n > r > :x; r[:since] < 2; r} do
    it { Proc.new { r=rel('r?'); n=node(2); n > r > :x; r[:since] < 2; r }.should be_cypher(%q[START n0=node(2) MATCH (n0)-[r?]->(x) WHERE r.since < 2 RETURN r]) }
  end

  describe %{n=node(3, 1); where((n[:age] < 30) & ((n[:name] == 'foo') | (n[:size] > n[:age]))); ret n} do
    it { Proc.new { n=node(3, 1); where((n[:age] < 30) & ((n[:name] == 'foo') | (n[:size] > n[:age]))); ret n }.should be_cypher(%q[START n0=node(3,1) WHERE (n0.age < 30) and ((n0.name = "foo") or (n0.size > n0.age)) RETURN n0]) }
  end

  describe %{ n=node(3).as(:n); where((n[:desc] =~ /.\d+/) ); ret n} do
    it { Proc.new { n=node(3).as(:n); where(n[:desc] =~ /.\d+/); ret n }.should be_cypher(%q[START n=node(3) WHERE n.desc =~ /.\d+/ RETURN n]) }
  end

  describe %{ n=node(3).as(:n); where((n[:desc] =~ ".d+") ); ret n} do
    it { Proc.new { n=node(3).as(:n); where(n[:desc] =~ ".d+"); ret n }.should be_cypher(%q[START n=node(3) WHERE n.desc =~ /.d+/ RETURN n]) }
  end

  describe %{ n=node(3).as(:n); where((n[:desc] == /.\d+/) ); ret n} do
    it { Proc.new { n=node(3).as(:n); where(n[:desc] == /.\d+/); ret n }.should be_cypher(%q[START n=node(3) WHERE n.desc =~ /.\d+/ RETURN n]) }
  end

  describe %{n=node(3,4); n[:desc] == "hej"; n} do
    it { Proc.new { n=node(3, 4); n[:desc] == "hej"; n }.should be_cypher(%q[START n0=node(3,4) WHERE n0.desc = "hej" RETURN n0]) }
  end

  describe %{node(3,4) <=> :x; node(:x)[:desc] =~ /hej/; :x} do
    it { Proc.new { node(3, 4) <=> :x; node(:x)[:desc] =~ /hej/; :x }.should be_cypher(%q[START n0=node(3,4) MATCH (n0)--(x) WHERE x.desc =~ /hej/ RETURN x]) }
  end

  describe %{ a, x=node(1), node(2); p = shortest_path { a > '?*' > x }; p } do
    it { Proc.new { a, x=node(1), node(2); p = shortest_path { a > '?*' > x }; p }.should be_cypher(%{START n0=node(1),n1=node(2) MATCH m3 = shortestPath((n0)-[?*]->(n1)) RETURN m3}) }
  end

  describe %{shortest_path{node(1) > '?*' > node(2)}} do
    it { Proc.new { shortest_path { node(1) > '?*' > node(2) } }.should be_cypher(%{START n0=node(1),n2=node(2) MATCH m3 = shortestPath((n0)-[?*]->(n2)) RETURN m2}) }
  end

  describe %{shortest_path { node(1) > '?*' > :x > ':friend' > node(2)}} do
    it { Proc.new { shortest_path { node(1) > '?*' > :x > ':friend' > node(2) } }.should be_cypher(%{START n0=node(1),n2=node(2) MATCH m3 = shortestPath((n0)-[?*]->(x)-[:friend]->(n2)) RETURN m2}) }
  end

  describe "a=node(3); a > ':knows' > node(:b) > ':knows' > :c; :c" do
    it { Proc.new { a=node(3); a > ':knows' > node(:b) > ':knows' > :c; :c }.should be_cypher(%{START n0=node(3) MATCH (n0)-[:knows]->(b)-[:knows]->(c) RETURN c}) }
  end

  describe "a=node(3); a < ':knows' < :c; :c" do
    it { Proc.new { a=node(3); a < ':knows' < :c; :c }.should be_cypher(%{START n0=node(3) MATCH (n0)<-[:knows]-(c) RETURN c}) }
  end

  describe "a=node(3); a < ':knows' < node(:c) < :friends < :d; :friends" do
    it { Proc.new { a=node(3); a < ':knows' < node(:c) < :friends < :d; :friends }.should be_cypher(%{START n0=node(3) MATCH (n0)<-[:knows]-(c)<-[friends]-(d) RETURN friends}) }
  end

  describe "a=node(3); a < ':knows' < node(:c) > :friends > :d; :friends" do
    it { Proc.new { a=node(3); a < ':knows' < node(:c) > :friends > :d; :friends }.should be_cypher(%{START n0=node(3) MATCH (n0)<-[:knows]-(c)-[friends]->(d) RETURN friends}) }
  end

  describe "node(3) - ':knows' - :c; :c" do
    it { Proc.new { node(3) - ':knows' - :c; :c }.should be_cypher(%{START n0=node(3) MATCH (n0)-[:knows]-(c) RETURN c}) }
  end

  describe %{a = node(3); a - ':knows' - :c - ":friends" - :d; :c} do
    it { Proc.new { a = node(3); a - ':knows' - :c - ":friends" - :d; :c }.should be_cypher(%{START n0=node(3) MATCH (n0)-[:knows]-(c)-[:friends]-(d) RETURN c}) }
  end

  describe %{a=node(3); a > ':knows' > :b > ':knows' > :c; a -':blocks' - :d -':knows' -:c; [a, :b, :c, :d] } do
    it { Proc.new { a=node(3); a > ':knows' > :b > ':knows' > :c; a -':blocks' - :d -':knows' -:c; [a, :b, :c, :d] }.should be_cypher(%{START n0=node(3) MATCH (n0)-[:knows]->(b)-[:knows]->(c),(n0)-[:blocks]-(d)-[:knows]-(c) RETURN n0,b,c,d}) }
  end

  describe %{n=node(3); n > (r=rel('r')) > node; r.rel_type =~ /K.*/; r} do
    it { Proc.new { n=node(3); n > (r=rel('r')) > node; r.rel_type =~ /K.*/; r }.should be_cypher(%{START n0=node(3) MATCH (n0)-[r]->(v1) WHERE type(r) =~ /K.*/ RETURN r}) }
  end

  describe %{n=node(3, 1); n.property?(:belt); n} do
    it { Proc.new { n=node(3, 1); n.property?(:belt); n }.should be_cypher(%{START n0=node(3,1) WHERE has(n0.belt) RETURN n0}) }
  end

  describe %{n=node(3,1); n[:belt?] == "white";n} do
    it { Proc.new { n=node(3, 1); n[:belt?] == "white"; n }.should be_cypher(%{START n0=node(3,1) WHERE n0.belt? = "white" RETURN n0}) }
  end

  describe %{a=node(1).as(:a);b=node(3,2); r=rel('r?'); a < r < b; r.exist? ; b} do
    it { Proc.new { a=node(1).as(:a); b=node(3, 2); r=rel('r?'); a < r < b; r.exist?; b }.should be_cypher(%{START a=node(1),n1=node(3,2) MATCH (a)<-[r?]-(n1) WHERE (r is null) RETURN n1}) }
  end

  describe %{names = ["Peter", "Tobias"]; a=node(3,1,2).as(:a); a[:name].in?(names); ret a} do
    it { Proc.new { names = ["Peter", "Tobias"]; a=node(3, 1, 2).as(:a); a[:name].in?(names); ret a }.should be_cypher(%{START a=node(3,1,2) WHERE (a.name IN ["Peter","Tobias"]) RETURN a}) }
  end

  describe %{node(3) >> :b} do
    it { Proc.new { node(3) >> :b }.should be_cypher(%{START n0=node(3) MATCH m2 = (n0)-->(b) RETURN m2}) }
  end

  describe %{p = node(3) >> :b; [:b, p.length]} do
    it { Proc.new { p = node(3) >> :b; [:b, p.length] }.should be_cypher(%{START n0=node(3) MATCH m2 = (n0)-->(b) RETURN b,length(m2)}) }
  end

  describe %{p = node(3) >> :b; [:b, p.length]} do
    it { Proc.new { p = node(3) >> :b; [:b, p.length] }.should be_cypher(%{START n0=node(3) MATCH m2 = (n0)-->(b) RETURN b,length(m2)}) }
  end

  describe %{p1 = (node(3).as(:a) > ":knows*0..1" > :b).as(:p1); p2=node(:b) > ':blocks*0..1' > :c; [:a,:b,:c, p1.length, p2.length]} do
    it { Proc.new { p1 = (node(3).as(:a) > ":knows*0..1" > :b).as(:p1); p2=node(:b) > ':blocks*0..1' > :c; [:a, :b, :c, p1.length, p2.length] }.should be_cypher(%{START a=node(3) MATCH p1 = (a)-[:knows*0..1]->(b),m3 = (b)-[:blocks*0..1]->(c) RETURN a,b,c,length(p1),length(m3)}) }
  end

  describe %{n=node(1,2).as(:n); n[:age?]} do
    it { Proc.new { n=node(1, 2).as(:n); n[:age?] }.should be_cypher(%{START n=node(1,2) RETURN n.age?}) }
  end

  describe %{n=node(1); n>>:b; n.distinct} do
    it { Proc.new { n=node(1); n>>:b; n.distinct }.should be_cypher(%{START n0=node(1) MATCH (n0)-->(b) RETURN distinct n0}) }
  end

  describe %{node(1)>>(b=node(:b)); b.distinct} do
    it { Proc.new { node(1)>>(b=node(:b)); b.distinct }.should be_cypher(%{START n0=node(1) MATCH (n0)-->(b) RETURN distinct b}) }
  end

  describe %{(n = node(2))>>:x; [n,count]} do
    it { Proc.new { (n = node(2))>>:x; [n, count] }.should be_cypher(%{START n0=node(2) MATCH (n0)-->(x) RETURN n0,count(*)}) }
  end

  describe %{DSL    (n = node(2))>>:x; count} do
    it { Proc.new { (n = node(2))>>:x; count }.should be_cypher(%{START n0=node(2) MATCH (n0)-->(x) RETURN count(*)}) }
  end

  describe %{DSL    r=rel('r'); node(2)>r>node; ret r.rel_type, count} do
    it { Proc.new { r=rel('r'); node(2)>r>node; ret r.rel_type, count }.should be_cypher(%{START n0=node(2) MATCH (n0)-[r]->(v1) RETURN type(r),count(*)}) }
  end

  describe %{DSL    node(2)>>:x; count(:x)} do
    it { Proc.new { node(2)>>:x; count(:x) }.should be_cypher(%{START n0=node(2) MATCH (n0)-->(x) RETURN count(x)}) }
  end

  describe %{DSL    n=node(2, 3, 4, 1); n[:property?].count} do
    it { Proc.new { n=node(2, 3, 4, 1); n[:property?].count }.should be_cypher(%{START n0=node(2,3,4,1) RETURN count(n0.property?)}) }
  end

  describe %{DSL    n=node(2, 3, 4); n[:property].sum} do
    it { Proc.new { n=node(2, 3, 4); n[:property].sum }.should be_cypher(%{START n0=node(2,3,4) RETURN sum(n0.property)}) }
  end

  describe %{DSL    n=node(2, 3, 4); n[:property].avg} do
    it { Proc.new { n=node(2, 3, 4); n[:property].avg }.should be_cypher(%{START n0=node(2,3,4) RETURN avg(n0.property)}) }
  end

  describe %{DSL    n=node(2, 3, 4); n[:property].max} do
    it { Proc.new { n=node(2, 3, 4); n[:property].max }.should be_cypher(%{START n0=node(2,3,4) RETURN max(n0.property)}) }
  end

  describe %{DSL    n=node(2, 3, 4); n[:property].min} do
    it { Proc.new { n=node(2, 3, 4); n[:property].min }.should be_cypher(%{START n0=node(2,3,4) RETURN min(n0.property)}) }
  end

  describe %{DSL    n=node(2, 3, 4); n[:property].collect} do
    it { Proc.new { n=node(2, 3, 4); n[:property].collect }.should be_cypher(%{START n0=node(2,3,4) RETURN collect(n0.property)}) }
  end

  describe %{DSL    n=node(2); n>>:b; n[:eyes].distinct.count} do
    it { Proc.new { n=node(2); n>>:b; n[:eyes].distinct.count }.should be_cypher(%{START n0=node(2) MATCH (n0)-->(b) RETURN count(distinct n0.eyes)}) }
  end

  describe %{DSL    node(3, 4, 5).neo_id} do
    it { Proc.new { node(3, 4, 5).neo_id }.should be_cypher(%{START n0=node(3,4,5) RETURN ID(n0)}) }
  end

  describe "        a = node(3); b=node(1); match p = a > '*1..3' > b; where p.nodes.all? { |x| x[:age] > 30 }; ret p" do
    it { Proc.new { a = node(3); b=node(1); match p = a > '*1..3' > b; where p.nodes.all? { |x| x[:age] > 30 }; ret p }.should be_cypher(%{START n0=node(3),n1=node(1) MATCH m3 = (n0)-[*1..3]->(n1) WHERE all(x in nodes(m3) WHERE x.age > 30) RETURN m3}) }
  end

  describe "DSL     a = node(2); a[:array].any? { |x| x == 'one' }; a" do
    it { Proc.new { a = node(2); a[:array].any? { |x| x == 'one' }; a }.should be_cypher(%{START n0=node(2) WHERE any(x in n0.array WHERE x = "one") RETURN n0}) }
  end

  describe "        p=node(3)>'*1..3'>:b; p.nodes.none? { |x| x[:age] == 25 };p" do
    it { Proc.new { p=node(3)>'*1..3'>:b; p.nodes.none? { |x| x[:age] == 25 }; p }.should be_cypher(%{START n0=node(3) MATCH m2 = (n0)-[*1..3]->(b) WHERE none(x in nodes(m2) WHERE x.age = 25) RETURN m2}) }
  end

  describe %{       p = node(3)>>:b; p.nodes.single? { |x| x[:eyes] == 'blue' }; p } do
    it { Proc.new { p = node(3)>>:b; p.nodes.single? { |x| x[:eyes] == 'blue' }; p }.should be_cypher(%{START n0=node(3) MATCH m2 = (n0)-->(b) WHERE single(x in nodes(m2) WHERE x.eyes = "blue") RETURN m2}) }
  end

  describe %{       p = node(3)>>:b; p.rels.single? { |x| x[:eyes] == 'blue' }; p } do
    it { Proc.new { p = node(3)>>:b; p.rels.single? { |x| x[:eyes] == 'blue' }; p }.should be_cypher(%{START n0=node(3) MATCH m2 = (n0)-->(b) WHERE single(x in relationships(m2) WHERE x.eyes = "blue") RETURN m2}) }
  end

  describe %{       a=node(3); b=node(4); c=node(1); p=a>>b>>c; p.nodes.extract { |x| x[:age] }} do
    it { Proc.new { a=node(3); b=node(4); c=node(1); p=a>>b>>c; p.nodes.extract { |x| x[:age] } }.should be_cypher(%{START n0=node(3),n1=node(4),n2=node(1) MATCH m4 = (n0)-->(n1)-->(n2) RETURN extract(x in nodes(m4) : x.age)}) }
  end

  describe %{       a=node(3); coalesce(a[:hair_colour?], a[:eyes?]) } do
    it { Proc.new { a=node(3); coalesce(a[:hair_colour?], a[:eyes?]) }.should be_cypher(%{START n0=node(3) RETURN coalesce(n0.hair_colour?, n0.eyes?)}) }
  end

  describe %{       a=node(2); ret a[:array], a[:array].head } do
    it { Proc.new { a=node(2); ret a[:array], a[:array].head }.should be_cypher(%{START n0=node(2) RETURN n0.array,head(n0.array)}) }
  end

  describe %{       a=node(2); ret a[:array], a[:array].last } do
    it { Proc.new { a=node(2); ret a[:array], a[:array].last }.should be_cypher(%{START n0=node(2) RETURN n0.array,last(n0.array)}) }
  end

  describe %{       a=node(3); c = node(2); p = a >> :b >> c; nodes(p) } do
    it { Proc.new { a=node(3); c = node(2); p = a >> :b >> c; nodes(p) }.should be_cypher(%{START n0=node(3),n1=node(2) MATCH m3 = (n0)-->(b)-->(n1) RETURN nodes(m3)}) }
  end


  describe %{       a=node(3); c = node(2); p = a >> :b >> c; rels(p) } do
    it { Proc.new { a=node(3); c = node(2); p = a >> :b >> c; rels(p) }.should be_cypher(%{START n0=node(3),n1=node(2) MATCH m3 = (n0)-->(b)-->(n1) RETURN relationships(m3)}) }
  end

  if RUBY_VERSION > "1.9.0"
    # the ! operator is only available in Ruby 1.9.x
    describe %{n=node(3).as(:n); where(!(n[:desc] =~ ".\d+")); ret n} do
      it { Proc.new { n=node(3).as(:n); where(!(n[:desc] =~ ".\d+")); ret n }.should be_cypher(%q[START n=node(3) WHERE not(n.desc =~ /.d+/) RETURN n]) }
    end

    describe %{n=node(3).as(:n); where((n[:desc] != "hej")); ret n} do
      it { Proc.new { n=node(3).as(:n); where((n[:desc] != "hej")); ret n }.should be_cypher(%q[START n=node(3) WHERE n.desc != "hej" RETURN n]) }
    end

    describe %{a=node(1).as(:a);b=node(3,2); r=rel('r?'); a < r < b; !r.exist? ; b} do
      it { Proc.new { a=node(1).as(:a); b=node(3, 2); r=rel('r?'); a < r < b; !r.exist?; b }.should be_cypher(%{START a=node(1),n1=node(3,2) MATCH (a)<-[r?]-(n1) WHERE not(r is null) RETURN n1}) }
    end

  end

end