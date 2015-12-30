module Neo4j
  # A relationship between two nodes in the graph. A relationship has a start node, an end node and a type.
  # You can attach properties to relationships like Neo4j::Node.
  #
  # The fact that the relationship API gives meaning to start and end nodes implicitly means that all relationships have a direction.
  # In the example above, rel would be directed from node to otherNode.
  # A relationship's start node and end node and their relation to outgoing and incoming are defined so that the assertions in the following code are true:
  #
  # Furthermore, Neo4j guarantees that a relationship is never "hanging freely,"
  # i.e. start_node, end_node and other_node are guaranteed to always return valid, non-nil nodes.
  class Relationship
    # A module that allows plugins to register wrappers around Neo4j::Node objects
    module Wrapper
      # Used by Neo4j::NodeMixin to wrap nodes
      def wrapper
        self
      end

      def neo4j_obj
        self
      end
    end

    include PropertyContainer
    include EntityEquality
    include Wrapper
    include EntityMarshal

    # @return [Hash<Symbol,Object>] all properties of the relationship
    def props
      fail 'not implemented'
    end

    # replace all properties with new properties
    # @param [Hash] properties a hash of properties the relationship should have
    def props=(properties)
      fail 'not implemented'
    end

    # Updates the properties, keeps old properties
    # @param [Hash<Symbol,Object>] properties hash of properties that should be updated on the relationship
    def update_props(properties)
      fail 'not implemented'
    end

    # Directly remove the property on the relationship (low level method, may need transaction)
    def remove_property(key)
      fail 'not implemented'
    end

    # Directly set the property on the relationship (low level method, may need transaction)
    # @param [Hash, String] key
    # @param value see Neo4j::PropertyValidator::VALID_PROPERTY_VALUE_CLASSES for valid values
    def set_property(key, value)
      fail 'not implemented'
    end

    # Directly get the property on the relationship (low level method, may need transaction)
    # @param [Hash, String] key
    # @return the value of the key
    def get_property(key, value)
      fail 'not implemented'
    end

    # Returns the start node of this relationship.
    # @return [Neo4j::Node,Object] the node or wrapped node
    def start_node
      _start_node.wrapper
    end

    # Same as #start_node but does not wrap the node
    # @return [Neo4j::Node]
    def _start_node
      fail 'not implemented'
    end

    # Returns the end node of this relationship.
    # @return [Neo4j::Node,Object] the node or wrapped node
    def end_node
      _end_node.wrapper
    end

    # Same as #end_node but does not wrap the node
    # @return [Neo4j::Node]
    def _end_node
      fail 'not implemented'
    end

    # @abstract
    def del
      fail 'not implemented'
    end

    # The unique neo4j id
    # @abstract
    def neo_id
      fail 'not implemented'
    end

    # @return [true, false] if the relationship exists
    # @abstract
    def exist?
      fail 'not implemented'
    end

    # Returns the relationship name
    #
    # @example
    #   a = Neo4j::Node.new
    #   a.create_rel(:friends, node_b)
    #   a.rels.first.rel_type # => :friends
    # @return [Symbol] the type of the relationship
    def rel_type
      fail 'not implemented'
    end

    # A convenience operation that, given a node that is attached to this relationship, returns the other node.
    # For example if node is a start node, the end node will be returned, and vice versa.
    # This is a very convenient operation when you're manually traversing the node space by invoking one of the #rels
    # method on a node. For example, to get the node "at the other end" of a relationship, use the following:
    #
    # @example
    #   end_node = node.rels.first.other_node(node)
    #
    # @raise This operation will throw a runtime exception if node is neither this relationship's start node nor its end node.
    #
    # @param [Neo4j::Node] node the node that we don't want to return
    # @return [Neo4j::Node] the other node wrapper
    # @see #_other_node
    def other_node(node)
      _other_node(node.neo4j_obj).wrapper
    end

    # Same as #other_node but can return a none wrapped node
    def _other_node(node)
      if node == _start_node
        _end_node
      elsif node == _end_node
        _start_node
      else
        fail "Node #{node.inspect} is neither start nor end node"
      end
    end


    class << self
      def create(rel_type, from_node, other_node, props = {})
        from_node.neo4j_obj.create_rel(rel_type, other_node, props)
      end

      def load(neo_id, session = Neo4j::Session.current)
        rel = _load(neo_id, session)
        rel && rel.wrapper
      end

      def _load(neo_id, session = Neo4j::Session.current)
        session.load_relationship(neo_id)
      end
    end
  end
end
