module Neo4j::Server
  class CypherNode
    include Neo4j::Server::Resource

    def initialize(db)
      @db = db
    end

    def neo_id
      # TODO DRY
      resource_url_id
    end

    # TODO, needed by neo4j-cypher
    def _java_node
      self
    end


    def []=(key,value)
      RestDatabase.query(self) {|node| node[key]=value; node}
      value
    end

    def [](key)
      r = RestDatabase.query(self) {|node| node[key]}
      r['data'][0][0]
    end

    def exist?
      response = @db.query(self) {|node| node }
      return true if response.code == 200
      body = JSON.parse(response.body)
      if response.code == 400 && body['exception'] == 'EntityNotFoundException'
        return false
      end

      raise "Illegal response #{response.code} body #{response.body} from server"
    end

  end
end