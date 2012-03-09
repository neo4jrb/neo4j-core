module Neo4j
  module Core
    module Rels

      # Traverse relationships of depth one from one node.
      # This object is returned from the Neo4j::Node#rels method.
      # @see Neo4j::Core::Node#rels
      class Traverser
        include Enumerable
        include Neo4j::Core::ToJava

        attr_reader :node
        attr_reader :dir
        attr_reader :types

        # Called from Neo4j::Core::Node#rels
        def initialize(node, types, dir = :both)
          @node = node
          @types = types
          @dir = dir
        end

        def to_s
          "#{self.class} [types: #{@types.join(',')} dir:#{@dir}]"
        end

        # Implements the Ruby Enumerable mixin
        def each
          iter = iterator
          while (iter.has_next())
            rel = iter.next
            yield rel.wrapper if match_to_other?(rel)
          end
        end

        # @return [true,false] if there are no relationships of specified dir and type(s)
        def empty?
          first == nil
        end

        # @return The Java Iterator
        def iterator
          @node._rels(@dir, *@types)
        end

        # @return [Fixnum] the size of all matched relationship, also check if it #to_other node
        # @see #to_other
        def size
          c = 0
          iter = iterator
          while (iter.has_next())
            rel = iter.next
            next unless match_to_other?(rel)
            c += 1
          end
          c
        end


        # @return [true,false] true if it match the specified other node
        # @see #to_other
        def match_to_other?(rel)
          if @to_other.nil?
            true
          elsif @dir == :outgoing
            rel._end_node == @to_other
          elsif @dir == :incoming
            rel._start_node == @to_other
          else
            rel._start_node == @to_other || rel._end_node == @to_other
          end
        end

        # Specifies that we only want relationship to the given node
        # @param [Neo4j::Node] to_other a node or an object that implements the Neo4j::Core::Equal mixin
        # @return self
        def to_other(to_other)
          @to_other = to_other
          self
        end

        # Deletes all the relationships
        def del
          each { |rel| rel.del }
        end


        # Specifies that we want both incoming and outgoing direction
        # @return self
        def both
          @dir = :both
          self
        end

        # Specifies that we only want incoming relationships
        # @return self
        def incoming
          @dir = :incoming
          self
        end

        # Specifies that only outgoing relationships is wanted.
        # @return self
        def outgoing
          @dir = :outgoing
          self
        end

      end

    end
  end
end