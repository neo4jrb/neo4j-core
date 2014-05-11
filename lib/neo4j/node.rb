module Neo4j

  # The base class for both the Embedded and Server Neo4j Node
  # Notice this class is abstract and can't be instantiated
  class Node

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

    include EntityEquality
    include Wrapper
    include PropertyContainer

    # @return [Hash] all properties of the node
    def props()
      raise 'not implemented'
    end

    # replace all properties with new properties
    # @param [Hash] hash a hash of properties the node should have
    def props=(hash)
      raise 'not implemented'
    end

    # Updates the properties, keeps old properties
    # @param [Hash] hash hash of properties that should be updated on the node
    def update_props(hash)
      raise 'not implemented'
    end

    # Directly remove the property on the node (low level method, may need transaction)
    def remove_property(key)
      raise 'not implemented'
    end

    # Directly set the property on the node (low level method, may need transaction)
    # @param [Hash, String] key
    # @param value see Neo4j::PropertyValidator::VALID_PROPERTY_VALUE_CLASSES for valid values
    def set_property(key, value)
      raise 'not implemented'
    end

    # Directly get the property on the node (low level method, may need transaction)
    # @param [Hash, String] key
    # @return the value of the key
    def get_property(key, value)
      raise 'not implemented'
    end

    # Creates a relationship of given type to other_node with optionally properties
    # @param [Symbol] type the type of the relation between the two nodes
    # @param [Neo4j::Node] other_node the other node
    # @param [Hash] props optionally properties for the created relationship
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
    def rels(match = {dir: :both})
      raise 'not implemented'
    end

    # Adds one or more Neo4j labels on the node
    def add_label(*labels)
      raise 'not implemented'
    end

    # Sets label on the node. Any old labels will be removed
    def set_label(*labels)
      raise 'not implemented'
    end

    # Delete given labels
    def delete_label(*labels)
      raise 'not implemented'
    end

    #
    # @return all labels on the node
    def labels()
      raise 'not implemented'
    end

    # Deletes this node from the database
    def del()
      raise 'not implemented'
    end

    # @return true if the node exists in the database
    def exist?
      raise 'not implemented'
    end

    # @returns all the Neo4j labels for this node
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
    # @param (see #rel)
    def node(specs = {})
      raise 'not implemented'
    end

    # Same as #node but returns the relationship. Notice it may raise an exception if there are more then one relationship matching.
    def rel(spec = {})
      raise 'not implemented'
    end

    def _rel(spec = {})
      raise 'not implemented'
    end

    # Returns true or false if there is one or more relationships
    # Same as `!! #rel()`
    def rel?(spec = {})
      raise 'not implemented'
    end

    # Same as Neo4j::Node#exist?
    def exist?
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
      # Creates a node
      def create(props=nil, *labels_or_db)
        session = Neo4j::Core::ArgumentHelper.session(labels_or_db)
        session.create_node(props, labels_or_db)
      end

      # Loads a node from the database with given id
      def load(neo_id, session = Neo4j::Session.current)
        node = _load(neo_id, session)
        node && node.wrapper
      end

      # Same as #load but does not try to return a wrapped node
      # @return [Neo4j::Node] an unwrapped node
      def _load(neo_id, session = Neo4j::Session.current)
        session.load_node(neo_id)
      end

      # Checks if the given entity node or entity id (Neo4j::Node#neo_id) exists in the database.
      # @return [true, false] if exist
      def exist?(entity_or_entity_id, session = Neo4j::Session.current)
        session.node_exist?(neo_id)
      end

      # Find the node with given label and value
      def find_nodes(label, value=nil, session = Neo4j::Session.current)
        session.find_nodes(label, value)
      end
    end

    def initialize
      raise "Can't instantiate abstract class" if abstract_class?
      puts "Instantiated!"
    end

    private
    def abstract_class?
      self.class == Node
    end


  end

end