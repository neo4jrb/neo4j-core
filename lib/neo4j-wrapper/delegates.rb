module Neo4j::Wrapper::Delegates
  class << self
    private
    # @macro  [new] node.delegate
    #   @method $1(*args, &block)
    #   Delegates to {http://rdoc.info/github/andreasronge/neo4j-core/master/Neo4j/Core/$2#$1-instance_method Neo4j::Core::Node#$1} using the <tt>_unwrapped_node</tt> instance with the supplied parameters.
    #   @see Neo4j::NodeMixin#_unwrapped_node
    #   @see http://rdoc.info/github/andreasronge/neo4j-core/master/Neo4j/Core/$2#$1-instance_method Neo4j::Core::Node#$1
    def delegate(*args)
      method_name = args.first
      class_eval(<<-EOM, __FILE__, __LINE__)
              def #{method_name}(*args, &block)
                _unwrapped_node.send(:#{method_name}, *args, &block)
              end
      EOM
    end
  end

  delegate :labels, 'Something'

  # Methods included from Core::Property
  # [], #[]=, #neo_id, #property?, #props, #update

  # @macro  node.delegate
  delegate :[]=, 'Property'

  # @macro  node.delegate
  delegate :[], 'Property'

  # @macro  node.delegate
  delegate :property?, 'Property'

  # @macro  node.delegate
  delegate :props, 'Property'

  # @macro  node.delegate
  delegate :update, 'Property'

  # @macro  node.delegate
  delegate :neo_id, 'Property'


  #Methods included from Core::Rels
  # _node, #_nodes, #_rel, #_rels, #node, #nodes, #rel, #rel?, #rels

  # @macro  node.delegate
  delegate :node, 'Rels'

  # @macro  node.delegate
  delegate :_node, 'Rels'

  # @macro  node.delegate
  delegate :nodes, 'Rels'

  # @macro  node.delegate
  delegate :_nodes, 'Rels'

  # @macro  node.delegate
  delegate :rel, 'Rels'

  # @macro  node.delegate
  delegate :_rel, 'Rels'

  # @macro  node.delegate
  delegate :rels, 'Rels'

  # @macro  node.delegate
  delegate :_rels, 'Rels'

  # @macro  node.delegate
  delegate :rel?, 'Rels'



  # Methods included from Core::Node
  # #del, #exist?

  # @macro  node.delegate
  delegate :del, 'Node'

  # @macro  node.delegate
  delegate :exist?, 'Node'

  # Methods included from Core::Property::Java
  #get_property, #graph_database, #property_keys, #remove_property, #set_property

  # @macro  node.delegate
  delegate :get_property, 'Property/Java'

  # @macro  node.delegate
  delegate :set_property, 'Property/Java'

  # @macro  node.delegate
  delegate :property_keys, 'Property/Java'

  # @macro  node.delegate
  delegate :remove_property, 'Property/Java'

  # Methods included from Core::Equal
  #==, #eql?, #equal?

  # @macro  node.delegate
  delegate :equal?, 'Equal'

  # @macro  node.delegate
  delegate :eql?, 'Equal'


  # @macro  node.delegate
  delegate :==

  # @macro  node.delegate
  delegate :neo_id

end
