# frozen_string_literal: true

module Neo4j
  module Core
    module BoltRouting
      class RoundRobinArrayIndex
        def initialize(offset = 0)
          @offset = offset
        end

        def next(array_length)
          return -1 if array_length.zero?

          next_offset = @offset
          @offset += 1

          next_offset % array_length
        end
      end
    end
  end
end
