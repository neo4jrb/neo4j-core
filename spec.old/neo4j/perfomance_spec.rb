#require 'spec_helper'
#
#class MyIndex
#  extend Neo4j::Core::Index::ClassMethods
#  extend Forwardable
#  include Neo4j::Core::Index
#  attr_reader :_java_entity
#
#  def_delegators :_java_entity, :[], :[]=
#
#  def initialize(props = {})
#    @_java_entity = self.class.new_node(props)
#  end
#
#  self.node_indexer do
#    index_names :exact => 'myindex_exact', :fulltext => 'myindex_fulltext'
#    trigger_on :myindex => true
#  end
#
#  def self.new_node (props = {})
#    Neo4j::Node.new(props.merge(:myindex => true))
#  end
#end
#
#
#describe "Neo4j::Node#index", :type => :integration do
#  MyIndex.index(:name) # default :exact
#  MyIndex.index(:things)
#  MyIndex.index(:age, :field_type => Fixnum) # default :exact
#  MyIndex.index(:wheels, :field_type => Fixnum)
#  MyIndex.index(:description, :type => :fulltext)
#
#  it "pefom" do
#    10.times do
#      t = Time.now
#      tx = new_tx
#      (0..1000).each do
#        MyIndex.new_node :things => 'bla', :name => 'foo', :age => 42, :wheels => 53, :description => "Bla bla"
#      end
#      d1 = Time.now - t
#      t = Time.now
#      finish_tx
#      d2 = Time.now - t
#      puts "Index #{d2}, create #{d1} tot #{d1 + d2} - #{(d2/(d1 + d2)).round(3)}"
#    end
#    tot = Neo4j::Core::Index::IndexerRegistry.instance.tot
#    puts "IndexerRegistry #{(tot/10).round(3)}"
#    #Index 0.192, create 0.032 tot 0.224 - 0.857
#    #IndexerRegistry 0.071
#
#    #Index 0.331, create 0.032 tot 0.363 - 0.912
#    #IndexerRegistry 0.127
#  end
#end