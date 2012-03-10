module Neo4j
  module Core
    module Traversal
      # Implements the Neo4j Predicate Java interface, only used internally.
      # @private
      class FilterPredicate
        include Java::OrgNeo4jHelpers::Predicate

        def initialize
          @procs = []
        end

        def add(proc)
          @procs << proc
        end

        def include_start_node
          @include_start_node = true
        end

        def accept(path)
          return false if @include_start_node && path.length == 0
          # find the first filter which returns false
          # if not found then we will accept this path
          @procs.find { |p| !p.call(path) }.nil?
        end
      end
    end
  end
end