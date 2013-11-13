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

    include PropertyContainer
    include EntityEquality

    # @abstract
    def start_node
      raise 'not implemented'
    end

    # @abstract
    def end_node
      raise 'not implemented'
    end

    # @abstract
    def del
      raise 'not implemented'
    end

    # The unique neo4j id
    # @abstract
    def neo_id
      raise 'not implemented'
    end

    # @return [true, false] if the relationship exists
    # @abstract
    def exist?
      raise 'not implemented'
    end

    # Returns the relationship name
    #
    # @example
    #   a = Neo4j::Node.new
    #   a.create_rel(:friends, node_b)
    #   a.rels.first.rel_type # => :friends
    # @return [Symbol] the type of the relationship
    def rel_type
      raise 'not implemented'
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
      if node == start_node
        return end_node
      elsif node == end_node
        return start_node
      else
        raise "Node #{node.inspect} is neither start nor end node"
      end
    end

    class << self
      def load(neo_id, session = Neo4j::Session.current)
        session.load_relationship(neo_id)
      end

    end
  end
end