module Neo4j::Server
  class CypherNode
    include Neo4j::Server::Resource

    def neo_id
      # TODO DRY
      resource_url_id
    end

    # TODO, needed by neo4j-cypher
    def _java_node
      self
    end


    def []=(key,value)
      query = Neo4j::Cypher.query(self) {|node| node[key]=value; node}
      self.class.exec_cypher(query.to_s)
      value
    end

    def [](key)
      query = Neo4j::Cypher.query(self) {|node| node[key]}
      r = Neo4j::Server::CypherNode.exec_cypher(query.to_s)
      r['data'][0][0]
    end

    class << self
      include Neo4j::Server::Resource

      def exec_cypher(cypher)
        url = resource_url('cypher')

        response = HTTParty.post(url, headers: resource_headers, body: {query: cypher}.to_json)
        expect_response_code(url, response, 200)
        JSON.parse(response.body)
      end

      def create_node(props = nil, *labels)
        query = Neo4j::Cypher.query { node.new }
        cypher_response = exec_cypher(query.to_s)
        node_data = cypher_response['data'][0][0]
        url = node_data['self']
        cypher_node = new
        cypher_node.init_resource_data(node_data,url)
        cypher_node
      end
    end
  end
end