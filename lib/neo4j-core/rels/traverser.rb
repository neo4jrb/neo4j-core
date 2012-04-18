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
          iterator.each do |rel|
            yield rel.wrapper if match_between?(rel)
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

        # @return [true,false] true if it match the specified other node
        # @see #between
        def match_between?(rel)
          if @between.nil?
            true
          elsif @dir == :outgoing
            rel._end_node == @between
          elsif @dir == :incoming
            rel._start_node == @between
          else
            rel._start_node == @between || rel._end_node == @between
          end
        end

        # Specifies that we only want relationship to the given node
        # @param [Neo4j::Node] between a node or an object that implements the Neo4j::Core::Equal mixin
        # @return self
        def between(between)
          @between = between
          self
        end

        alias_method :to_other, :between
        
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