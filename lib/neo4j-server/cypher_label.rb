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
      puts "CREATE INDEX #{properties.inspect}, #{response.inspect}"
    end


    def find_nodes(key=nil,value=nil)
      q = create_cypher_query(key,value)
      response = @session._query(q)
      return [] unless response.data
      Enumerator.new do |yielder|
        response.data.each do |data|
          first_column = data[0]
          yielder << CypherNode.new(self).init_resource_data(first_column,first_column['self'])
        end
      end
    end

    def drop_index(*properties)
      properties.each do |property|
        response = @session._query(@session.cypher_mapping.drop_index(@name, property))
        response.raise_error if response.error?
      end
    end


    def create_cypher_query(key,value)
      if (key)
        <<-CYPHER
          MATCH n:`#{@name}`
          USING INDEX n:`#{@name}`(#{key})
          WHERE n.#{key} = '#{value}'
          RETURN n
        CYPHER
      else
        <<-CYPHER
          MATCH n:`#{@name}` RETURN n
        CYPHER
      end
    end
  end
end