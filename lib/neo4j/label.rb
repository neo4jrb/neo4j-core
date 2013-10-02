module Neo4j
  class Label

    # @abstract
    def name
      raise 'not implemented'
    end

    # @abstract
    def find_nodes(key=nil, value=nil)
      raise 'not implemented'
    end

    # @abstract
    def create_index(*properties)
      raise 'not implemented'
    end

    # @abstract
    def drop_index(*properties)
      raise 'not implemented'
    end

    # List indices for a label
    # @abstract
    def indexes
      raise 'not implemented'
    end

    class << self
      def create(name, db = Neo4j::Database.instance)
        db.create_label(name)
      end
    end
  end

end