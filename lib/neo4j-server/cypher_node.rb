module Neo4j::Server
  class CypherNode #< Neo4j::Node
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
      props = JSON.parse(r.body)['data'][0][0]['data']
      props.keys.inject({}){|hash,key| hash[key.to_sym] = props[key]; hash}
    end

    def valid_property?(value)
      Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.include?(value.class)
    end

    def []=(key,value)
      unless valid_property?(value)
        raise Neo4j::InvalidPropertyException.new("Not valid Neo4j Property value #{value.class}, valid: #{Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.to_a.join(', ')}")
      end

      value = :NULL if value.nil?
      @db.query(self) {|node| node[key]=value; node}
      value
    end

    def [](key)
      r = @db.query(self) {|node| node["#{key}?"]}
      r['data'][0][0]
    end

    def del
      response = @db.query(self) {|node| node.del}
      expect_response_code(response, 200)
    end

    def exist?
      response = @db.query(self) {|node| node }
      return true if response.code == 200

      return false if response.code == 400 && response_exception(response) == 'EntityNotFoundException'

      handle_response_error(response)
    end

  end
end