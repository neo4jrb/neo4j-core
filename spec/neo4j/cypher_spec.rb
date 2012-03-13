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


describe "DSL { start n = node(3); match n <=> :x; ret :x }" do
  it { lambda { start n = node(3); match n <=> :x; ret :x }.should be_cypher("START n0=node(3) MATCH (n0)--(x) RETURN x") }
end


describe "DSL { x = node; n = node(3); match n <=> x; ret x }" do
  it { lambda { x = node; n = node(3); match n <=> x; ret x }.should be_cypher("START n0=node(3) MATCH (n0)--(v0) RETURN v0") }
end


describe "DSL { n = node(3).as(:n); n <=> node.as(:x); :x }" do
  it { lambda { n = node(3).as(:n); n <=> node.as(:x); :x }.should be_cypher("START n=node(3) MATCH (n)--(x) RETURN x") }
end


describe "DSL { node(3) <=> node(:x); :x }" do
  it { lambda { node(3) <=> node(:x); :x }.should be_cypher("START n0=node(3) MATCH (n0)--(x) RETURN x") }
end

describe "DSL { r = rel(0); ret r }" do
  it { lambda { r = rel(0); ret r }.should be_cypher("START r0=relationship(0) RETURN r0") }
end

describe "DSL { n = node(1, 2, 3); ret n }" do
  it { lambda { n = node(1, 2, 3); ret n }.should be_cypher("START n0=node(1,2,3) RETURN n0") }
end

describe %q[DSL query(FooIndex, "name:A")] do
  it { lambda { query(FooIndex, "name:A") }.should be_cypher(%q[START n0=node:fooindex_exact(name:A) RETURN n0]) }
end

describe %q[DSL query(FooIndex, "name:A", :fulltext)] do
  it { lambda { query(FooIndex, "name:A", :fulltext) }.should be_cypher(%q[START n0=node:fooindex_fulltext(name:A) RETURN n0]) }
end

describe %q[DSL lookup(FooIndex, "name", "A")] do
  it { lambda { lookup(FooIndex, "name", "A") }.should be_cypher(%q[START n0=node:fooindex_exact(name="A") RETURN n0]) }
end

describe %q[DSL lookup(FooIndex, "desc", "A")] do
  it { lambda { lookup(FooIndex, "desc", "A") }.should be_cypher(%q[START n0=node:fooindex_fulltext(desc="A") RETURN n0]) }
end

describe "DSL { a = node(1); b=node(2); ret(a, b) }" do
  it { lambda { a = node(1); b=node(2); ret(a, b) }.should be_cypher(%q[START n0=node(1),n1=node(2) RETURN n0,n1]) }
end

describe "DSL { [node(1), node(2)] }" do
  it { lambda { [node(1), node(2)] }.should be_cypher(%q[START n0=node(1),n1=node(2) RETURN n0,n1]) }
end

describe "DSL { node(3) >> :x; :x }" do
  it { lambda { node(3) >> :x; :x }.should be_cypher("START n0=node(3) MATCH (n0)-->(x) RETURN x") }
end

describe "DSL { node(3) > :r > :x; :r }" do
  it { lambda { node(3) > :r > :x; :r }.should be_cypher("START n0=node(3) MATCH (n0)-[r]->(x) RETURN r") }
end

describe "DSL { node(3) > 'r:friends' > :x; :r }" do
  it { lambda { node(3) > 'r:friends' > :x; :r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
end

describe "DSL { r = rel('r:friends').as(:r); node(3) > r > :x; r }" do
  it { lambda { r = rel('r:friends').as(:r); node(3) > r > :x; r }.should be_cypher("START n0=node(3) MATCH (n0)-[r:friends]->(x) RETURN r") }
end


#  node(3) > rel(:r) > :x; :r
#  node(3) >> rel(:r).type(:x) >> :x; :r
#  node(3) >> rel.type(:x) >> :x; :r
#  node(3) >> rel.type(:x) >> :x; :r
#  node(3) >> '[r]' >> :x; :r
#  node(3) >> '[k:r]' >> :x; :r
#
#  node(3) >> rel.as(:r) >> :x; :r
#  node(3) >> rel(:x).as(:r) >> :x; :r
#
#  rel.as(:r)
#  #MATCH p = a-[?*]->b
#  node(3) >> rel
#  # MATCH p = a-[?]->b
#  # me-->friend-[?:parent_of]->children
#  #MATCH a-[r?:LOVES]->()
#  r = rel("r?:LOVES")
#  node(3) >> r >> node; r
#
#  # START a=node(2)
#  #MATCH a-[?]->x
#  # RETURN x, x.name
#  a=node(2); x=node; a >> rel >> x; ret x, x[:name]
#  a=node(2); a >> rel >> node.as(:x); ret :x, 'x.name'
#  a=node(2).as(:a)
#end
#
#describe "START n0=node(3) MATCH (n0)-[:blocks]->(x) RETURN x", "start n = node(3); match n >> ['blocks'] >> :x; ret :x" do
#  node(3).as(:n) > rel(':blocks') > node.as(:x); :x
#  node(3) > :blocks > :x; :x
#  node(3) > 'r?:blocks' > :x; :x
#
#  r = rel('r?:blocks').as(:r); node(3) > r > :x; r
#
#
#end
#
#describe "START n0=node(3) MATCH (n0)-[:blocks]->(x) RETURN x", "node(3) >> 'blocks' >> :x; :x" do
#  node(3) > 'blocks' > :x; :x
#end