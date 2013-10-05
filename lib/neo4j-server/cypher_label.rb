module Neo4j::Server
  class CypherLabel
    extend Forwardable
    def_delegator :@session, :query_cypher_for
    attr_reader :name

    def initialize(session, name)
      @name = name
      @session = session
    end

    def create_index(*properties)
      response = query_cypher_for(:create_index, @name, properties)
      response.raise_error if response.error?
    end

    def drop_index(*properties)
      properties.each do |property|
        response = query_cypher_for(:drop_index, @name, property)
        response.raise_error if response.error? && !response.error_msg.match(/No such INDEX ON/)
      end
    end

  end
end