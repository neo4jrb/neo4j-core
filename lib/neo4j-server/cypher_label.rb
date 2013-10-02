module Neo4j::Server
  class CypherLabel < RestLabel

    def find_nodes(key=nil,value=nil)
      q = create_cypher_query(key,value)
      response = @db._query(q)
      return [] unless response.data
      Enumerator.new do |yielder|
        response.data.each do |data|
          first_column = data[0]
          yielder << CypherNode.new(self).init_resource_data(first_column,first_column['self'])
        end
      end
    end


    def create_cypher_query(key,value)
      if (key)
        puts "USING KEY #{key}"
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