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

    class << self
      def create(props=nil, db = Neo4j::Database.instance)
        # TODO
        raise "todo"
      end

      def load(neo_id, db = Neo4j::Database.instance)
        # TODO
        raise "todo"
      end

    end
  end
end