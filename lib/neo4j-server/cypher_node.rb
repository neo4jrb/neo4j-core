module Neo4j::Server
  class CypherNode < Neo4j::Node
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

    def props
      r = @db.query(self) { |node| node }
      props = r.first_data['data']
      props.keys.inject({}){|hash,key| hash[key.to_sym] = props[key]; hash}
    end

    def remove_property(key)
      @db.query(self) {|node| node[key]=:NULL}
    end

    def set_property(key,value)
      @db.query(self) {|node| node[key]=value}
      value
    end

    def get_property(key)
      r = @db.query(self) {|node| node[key]}
      r.first_data
    end

    def del
      @db.query(self) {|node| node.del}.raise_unless_response_code(200)
    end

    def exist?
      response = @db.query(self) {|node| node }
      if (!response.error?)
        return true
      elsif (response.exception == 'EntityNotFoundException')
        return false
      else
        handle_response_error(response.response)
      end
    end

  end
end