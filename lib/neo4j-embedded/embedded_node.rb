module Neo4j
  module Embedded
    class RelsIterator
      include Enumerable
      extend Neo4j::Core::TxMethods

      def initialize(node, match)
        @node = node
        ::Neo4j::Node.validate_match!(match)
        @match = match
      end

      def inspect
        'Enumerable<Neo4j::Relationship>'
      end

      def each(&block)
        @node._rels(@match).each { |r| block.call(r.wrapper) }
      end
      tx_methods :each

      def empty?
        first.nil?
      end
    end

    class NodesIterator
      include Enumerable
      extend Neo4j::Core::TxMethods

      def initialize(node, match)
        @node = node
        @match = match
      end

      def inspect
        'Enumerable<Neo4j::Node>'
      end

      def each(&block)
        @node._rels(@match).each { |r| block.call(r.other_node(@node)) }
      end
      tx_methods :each

      def empty?
        first.nil?
      end
    end

    class EmbeddedNode < Neo4j::Node
    end
  end
end
