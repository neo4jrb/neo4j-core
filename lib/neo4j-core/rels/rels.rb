module Neo4j
  module Core
    # Contains methods for traversing relationship object of depth one from one node.
    module Rels
      # Returns the only node of a given type and direction that is attached to this node, or nil.
      # This is a convenience method that is used in the commonly occuring situation where a node has exactly zero or one relationships of a given type and direction to another node.
      # Typically this invariant is maintained by the rest of the code: if at any time more than one such relationships exist, it is a fatal error that should generate an exception.

      # This method reflects that semantics and returns either:
      #  * nil if there are zero relationships of the given type and direction,
      #  * the relationship if there's exactly one, or
      #  * throws an unchecked exception in all other cases.
      #
      # This method should be used only in situations with an invariant as described above. In those situations, a "state-checking" method (e.g. #rel?) is not required,
      # because this method behaves correctly "out of the box."
      #
      # Does return the Ruby wrapper object (if it has a '_classname' property) unlike the #_node version of this method
      #
      def node(dir, type)
        n = _node(dir, type)
        n && n.wrapper
      end

      # Same as #node but instead returns an unwrapped native java node instead
      def _node(dir, type)
        r = _rel(dir, type)
        r && r._other_node(self._java_node)
      end

      # Returns an enumeration of relationship objects.
      # It always returns relationship of depth one.
      #
      # @example Return both incoming and outgoing relationships
      #   me.rels(:friends, :work).each {|relationship|...}
      #
      # @example Only return outgoing relationship of given type
      #   me.rels(:friends).outgoing.first.end_node # => my friend node
      #
      # @see [Neo4j::Relationship]
      # @return [Neo4j::Core::Rels::Traverser]
      def rels(*type)
        Traverser.new(self, type, :both)
      end


      # Returns the only relationship of a given type and direction that is attached to this node, or null.
      # This is a convenience method that is used in the commonly occuring situation where a node has exactly zero or
      # one relationships of a given type and direction to another node.
      # Typically this invariant is maintained by the rest of the code: if at any time more than one such relationships
      # exist, it is a fatal error that should generate an unchecked exception. This method reflects that semantics and
      # returns either:
      #
      # * nil if there are zero relationships of the given type and direction,
      # * the relationship if there's exactly one, or
      # * raise an exception in all other cases.
      def rel(dir, type)
        result = _rel(dir, type)
        result && result.wrapper
      end

      # Same as rel but does not return a ruby wrapped object but instead returns the Java object.
      def _rel(dir, type)
        get_single_relationship(ToJava.type_to_java(type), ToJava.dir_to_java(dir))
      end

      # Returns the raw java neo4j relationship object.
      def _rels(dir=:both, *types)
        if types.size > 1
          java_types = types.inject([]) { |result, type| result << ToJava.type_to_java(type) }.to_java(:'org.neo4j.graphdb.RelationshipType')
          get_relationships(java_types)
        elsif types.size == 1
          get_relationships(ToJava.type_to_java(types[0]), ToJava.dir_to_java(dir))
        elsif dir == :both
          get_relationships(ToJava.dir_to_java(dir))
        else
          raise "illegal argument, does not accept #{dir} #{types.join(',')} - only dir=:both for any relationship types"
        end
      end

      # Check if the given relationship exists
      # Returns true if there are one or more relationships from this node to other nodes
      # with the given relationship.
      #
      # @param [String,Symbol] type the key and value to be set, default any type
      # @param [Symbol] dir  optional default :both (either, :outgoing, :incoming, :both)
      # @return [Boolean] true if one or more relationships exists for the given type and dir otherwise false
      def rel? (type=nil, dir=:both)
        if type
          hasRelationship(ToJava.type_to_java(type), ToJava.dir_to_java(dir))
        else
          hasRelationship
        end
      end

    end

  end


end