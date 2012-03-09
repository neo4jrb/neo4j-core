module Neo4j
  module Core
    # A simple implementation of lazy map
    # @notice since we must support ruby 1.8.7 we can't use the fancy Enumerator block constructor for this.
    # @private
    class LazyMap
      include Enumerable

      def initialize(stuff, &map_block)
        @stuff = stuff
        @map_block = map_block
      end

      def each
        @stuff.each { |x| yield @map_block.call(x) }
      end

    end

  end
end
