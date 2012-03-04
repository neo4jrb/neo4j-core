class MyIndex
  #include
  extend Neo4j::Core::Index::ClassMethods
  include Neo4j::Core::Index

  node_indexer do
    inherit_from OtherClass
    index_names :exact => 'myindex_exact', :fulltext => 'myindex_fulltext'
    trigger{|event| event[:iname] == 'myindex'}
  end
end