module Neo4j

  module Wrapper
    # Used by Neo4j::NodeMixin to wrap nodes
    def wrapper
      self
    end
  end

  class Node

    include PropertyContainer
    include EntityEquality
    include Wrapper

    # @abstract
    def create_rel(type, other_node, props = nil)
      raise 'not implemented'
    end


    # Returns an enumeration of relationships.
    # It always returns relationships of depth one.
    #
    # @param [Hash] opts the options to create a message with.
    # @option opts [Symbol] :dir dir the direction of the relationship, allowed values: :both, :incoming, :outgoing.
    # @option opts [Symbol] :type the type of relationship to navigate
    # @option opts [Symbol] :between return all the relationships between this and given node
    # @return [Enumerable] of Neo4j::Relationship objects
    #
    # @example Return both incoming and outgoing relationships of any type
    #   node_a.rels
    #
    # @example All outgoing or incoming relationship of type friends
    #   node_a.rels(type: :friends)
    #
    # @example All outgoing relationships between me and another node of type friends
    #   node_a.rels(type: :friends, dir: :outgoing, between: node_b)
    #
    # @abstract
    def rels(opts = {dir: :both})
      raise 'not implemented'
    end

    # @abstract
    def add_label(*labels)
      raise 'not implemented'
    end

    # @abstract
    def exist?
      raise 'not implemented'
    end

    # @abstract
    def labels
      raise 'not implemented'
    end

    # Returns the only node of a given type and direction that is attached to this node, or nil.
    # This is a convenience method that is used in the commonly occuring situation where a node has exactly zero or one relationships of a given type and direction to another node.
    # Typically this invariant is maintained by the rest of the code: if at any time more than one such relationships exist, it is a fatal error that should generate an exception.
    #
    # This method reflects that semantics and returns either:
    # * nil if there are zero relationships of the given type and direction,
    # * the relationship if there's exactly one, or
    # * throws an exception in all other cases.
    #
    # This method should be used only in situations with an invariant as described above. In those situations, a "state-checking" method (e.g. #rel?) is not required,
    # because this method behaves correctly "out of the box."
    #
    # @abstract
    # @param (see #rel)
    def node(specs = {})
      raise 'not implemented'
    end

    # Same as #node but returns the relationship. Notice it may raise an exception if there are more then one relationship matching.
    def rel(spec = {})
      raise 'not implemented'
    end

    # Returns true or false if there is one or more relationships
    # Same as `!! #rel()`
    def rel?(spec = {})
      raise 'not implemented'
    end

    # Works like #rels method but instead returns the nodes.
    # It does try to load a Ruby wrapper around each node
    # @abstract
    # @param (see #rels)
    # @return [Enumerable] an Enumeration of either Neo4j::Node objects or wrapped Neo4j::Node objects
    # @notice it's possible that the same node is returned more then once because of several relationship reaching to the same node, see #outgoing for alternative
    def nodes(specs = {})
      #rels(specs).map{|n| n.other_node(self)}
    end

    class << self
      def create(props=nil, *labels_or_db)
        session = Neo4j::Core::ArgumentHelper.session(labels_or_db)
        session.create_node(props, labels_or_db)
      end

      def load(neo_id, session = Neo4j::Session.current)
        node = session.load_node(neo_id)
        node && node.wrapper
      end

      # Checks if the given entity node or entity id (Neo4j::Node#neo_id) exists in the database.
      # @return [true, false] if exist
      def exist?(entity_or_entity_id, session = Neo4j::Session.current)
        session.node_exist?(neo_id)
      end

      def find_nodes(label, value=nil, session = Neo4j::Session.current)
        session.find_nodes(label, value)
      end
    end
  end

end