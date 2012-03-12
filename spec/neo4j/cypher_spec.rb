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


def describe_cypher(cypher_result, query=nil, &query_dsl)

  describe "Cypher.new '#{query}'" do
    subject do
      Neo4j::Cypher.new query
    end

    its(:to_s) {should == cypher_result}
  end
end



describe_cypher "START n0=node(3) MATCH (n0)--(x) RETURN x", "start n = node(3); match n <=> :x; ret :x" do
  start n = node(3); match n <=> :x; ret :x
end

describe_cypher "START n0=node(3) MATCH (n0)--(x) RETURN x", "n = node(3); match n <=> :x; :x" do
  n = node(3); match n <=> :x; :x
end

describe_cypher "START n0=node(3) MATCH (n0)--(x) RETURN x", "n = node(3); n <=> :x; :x" do
  n = node(3); n <=> :x; :x
end

describe_cypher "START n0=node(3) MATCH (n0)--(x) RETURN x", "node(3) <=> :x; :x" do
  node(3) <=> :x; :x
end

describe_cypher "START r0=relationship(0) RETURN r0", "r = rel(0); ret r" do
  r = rel(0); ret r
end

describe_cypher "START n0=node(1,2,3) RETURN n0", "n = node(1,2,3); ret n" do
  n = node(1,2,3); ret n
end

describe_cypher %q[START n0=node:fooindex_exact(name:A) RETURN n0], %q[query(FooIndex, "name:A")] do
  query(FooIndex, "name:A")
end

describe_cypher %q[START n0=node:fooindex_fulltext(name:A) RETURN n0], %q[query(FooIndex, "name:A", :fulltext)] do
  query(FooIndex, "name:A", :fulltext)
end

describe_cypher %q[START n0=node:fooindex_exact(name="A") RETURN n0], %q[lookup(FooIndex, "name", "A")] do
  lookup(FooIndex, "name", "A")
end

describe_cypher %q[START n0=node:fooindex_fulltext(desc="A") RETURN n0], %q[lookup(FooIndex, "desc", "A")] do
  lookup(FooIndex, "desc", "A")
end

describe_cypher %q[START n0=node(1),n1=node(2) RETURN n0,n1], "a = node(1); b=node(2); ret(a,b)" do
  a = node(1); b=node(2); ret(a,b)
end

describe_cypher %q[START n0=node(1),n1=node(2) RETURN n0,n1], "[node(1), node(2)]" do
  [node(1), node(2)]
end

describe_cypher "START n0=node(3) MATCH (n0)-->(x) RETURN x", "node(3) >> :x; :x" do
  node(3) >> :x; :x
end

describe_cypher "START n0=node(3) MATCH (n0)-[r]->(x) RETURN r", "node(3) >> [:r] >> :x; :r" do
  node(3) >> [:r] >> :x; :r
end