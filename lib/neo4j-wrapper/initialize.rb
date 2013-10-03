module Neo4j::Wrapper::Initialize

  # Init this node with the specified java neo node
  # @param [Neo4j::Node] java_node the node this instance wraps
  def init_on_load(java_node)
    @_java_node = java_node
  end


  # Creates a new node and initialize with given properties.
  # You can override this to provide your own initialization.
  #
  # @param [Object, :each_pair] args if the first item in the list implements :each_pair then it will be initialize with those properties
  def init_on_create(*args)
    if args[0].respond_to?(:each_pair)
      args[0].each_pair { |k, v| respond_to?("#{k}=") ? self.send("#{k}=", v) : _java_entity[k] = v }
    end
  end

  # @return [Neo4j::Node] Returns the org.neo4j.graphdb.Node wrapped object
  # @see http://rdoc.info/github/andreasronge/neo4j-core/master/Neo4j/Node
  def _java_node
    @_java_node
  end

  # Implements the Neo4j::Node#wrapper and Neo4j::Relationship#wrapper method
  # so that we don't have to care if the node is wrapped or not.
  # @return self
  def wrapper
    self
  end

  alias_method :_java_entity, :_java_node


  module ClassMethods

    # Creates a new node or loads an already existing Neo4j node.
    #
    # You can use two callback method to initialize the node
    # init_on_load - this method is called when the node is loaded from the database
    # init_on_create - called when the node is created, will be provided with the same argument as the new method
    #
    # == Does
    # * creates a neo4j node java object (in @_java_node)
    #
    # If you want to provide your own initialize method you should instead implement the
    # method init_on_create method.
    #
    # @example Create your own Ruby wrapper around a Neo4j::Node java object
    #   class MyNode
    #     include Neo4j::NodeMixin
    #   end
    #
    #   node = MyNode.new(:name => 'jimmy', :age => 23)
    #
    # @example Using your own initialize method
    #   class MyNode
    #     include Neo4j::NodeMixin
    #
    #     def init_on_create(name, age)
    #        self[:name] = name
    #        self[:age] = age
    #     end
    #   end
    #
    #   node = MyNode.new('jimmy', 23)
    #
    # @param args typically a hash of properties, but could be anything which will be given to the init_on_create method
    # @return the object return from the super method
    def create(*args)
      # get the label
      db = Neo4j::Core::ArgumentHelper.db(args)
      props = args[0] if args[0].is_a?(Hash)
      node = db.create_node(props, labels)
      wrapped_node = new()
#          Neo4j::IdentityMap.add(node, wrapped_node)
      wrapped_node.init_on_load(node)
      wrapped_node.init_on_create(*args)
      wrapped_node
    end

    # Loads a wrapped node from the database given a neo id.
    # @param [#to_i, nil] neo_id
    # @return [Object, nil] If the node does not exist it will return nil otherwise the loaded node or wrapped node.
    # @note it will return nil if the node returned is not kind of this class
    def load_entity(neo_id, db=Neo4j::Database.instance)
      node = db.get_node_by_id(neo_id)
      label_names = node.get_labels.map(&:name)
      return nil if node.nil?
      node.kind_of?(self) ? node : nil
    end

  end

end


