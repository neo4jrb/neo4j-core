module Neo4j
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

    # @abstract
    def neo_id
      raise 'not implemented'
    end

    # @abstract
    def exist?
      raise 'not implemented'
    end

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