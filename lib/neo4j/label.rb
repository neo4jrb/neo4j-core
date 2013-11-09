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
      include Neo4j::Core::CypherTranslator

      def create(name, session = Neo4j::Session.current)
        session.create_label(name)
      end

      def query(label_name, query, session = Neo4j::Session.current)
        cypher = "MATCH (n:`#{label_name}`)"
        cypher += condition_to_cypher(query) if query[:conditions] && !query[:conditions].empty?
        cypher += session.query_default_return
        cypher += order_to_cypher(query) if query[:order]

        response = session._query_or_fail(cypher)
        session.search_result_to_enumerable(response) # TODO make it work in Embedded and refactor
      end


      def find_all_nodes(label_name, session = Neo4j::Session.current)
        session.find_all_nodes(label_name)
      end

      def find_nodes(label_name, key, value, session = Neo4j::Session.current)
        session.find_nodes(label_name, key, value)
      end

      private

      def condition_to_cypher(query)
        conditions = query[:conditions]
        " WHERE " + conditions.keys.map do |k|
          "n.#{k}=#{escape_value(conditions[k])}"
        end.join(" AND ")
      end

      def order_to_cypher(query)
        cypher = " ORDER BY "
        order = query[:order]

        handleHash = Proc.new do |hash|
          if (hash.is_a?(Hash))
            k, v = hash.first
            raise "only :asc or :desc allowed in order, got #{query.inspect}" unless [:asc, :desc].include?(v)
            v.to_sym == :asc ? "n.`#{k}`" : "n.`#{k}` DESC"
          else
            "n.`#{hash}`" unless hash.is_a?(Hash)
          end
        end

        case order
          when Array
            cypher += order.map(&handleHash).join(', ')
          when Hash
            cypher += handleHash.call(order)
          else
            cypher += "n.`#{order}`"
        end

        cypher
      end
    end
  end

end