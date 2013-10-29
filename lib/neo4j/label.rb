module Neo4j
  class Label

    # @abstract
    def name
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
      def create(name, session = Neo4j::Session.current)
          session.create_label(name)
      end

      def find_all_nodes(label_name, session = Neo4j::Session.current)
        session.find_all_nodes(label_name)
      end

      def find_nodes(label_name, key,value, session = Neo4j::Session.current)
        session.find_nodes(label_name, key,value)
      end

    end
  end

end