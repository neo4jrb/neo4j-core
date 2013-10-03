module Neo4j::Server
  class CypherLabel

    attr_reader :name

    def initialize(session, name)
      @name = name
      @session = session
    end

    def create_index(*properties)
      response = @session._query(@session.cypher_mapping.create_index(@name, properties))
      response.raise_error if response.error?
    end


    def find_nodes(key=nil,value=nil)
      q = create_cypher_query(key,value)
      response = @session._query(q)
      response.raise_error if response.error?
      return [] unless response.data
      Enumerator.new do |yielder|
        response.data.each do |data|
          yielder << CypherNode.new(@sessopm, data[0])
        end
      end
    end

    def drop_index(*properties)
      properties.each do |property|
        response = @session._query(@session.cypher_mapping.drop_index(@name, property))
        response.raise_error if response.error? && !response.error_msg.match(/No such INDEX ON/)
      end
    end


    def create_cypher_query(key,value)
      if (key)
        <<-CYPHER
          MATCH (n:`#{@name}`)
          USING INDEX n:`#{@name}`(#{key})
          WHERE n.#{key} = '#{value}'
          RETURN ID(n)
        CYPHER
      else
        <<-CYPHER
          MATCH (n:`#{@name}`) RETURN ID(n)
        CYPHER
      end
    end
  end
end