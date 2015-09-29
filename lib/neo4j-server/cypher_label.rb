module Neo4j
  module Server
    class CypherLabel < Neo4j::Label
      extend Forwardable
      def_delegator :@session, :query_cypher_for
      attr_reader :name

      def initialize(session, name)
        @name = name
        @session = session
      end

      def create_index(property, options = {}, session = Neo4j::Session.current)
        validate_index_options!(options)
        properties = property.is_a?(Array) ? property.join(',') : property
        response = session._query("CREATE INDEX ON :`#{@name}`(#{properties})")
        response.raise_error if response.error?
      end

      def drop_index(property, options = {}, session = Neo4j::Session.current)
        validate_index_options!(options)
        response = session._query("DROP INDEX ON :`#{@name}`(#{property})")
        response.raise_error if response.error? && !response.error_msg.match(/No such INDEX ON/)
      end

      def indexes
        @session.indexes(@name)
      end

      def uniqueness_constraints
        @session.uniqueness_constraints(@name)
      end
    end
  end
end
