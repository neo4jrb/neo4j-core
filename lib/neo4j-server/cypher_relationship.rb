module Neo4j::Server

  #POST /db/data/cypher {"query" : "START v1=node(1) WITH v1 CREATE (v1)-[r:`friends` {since: 2000}]->(v2 {name : 'Andreas'}) RETURN r"}
  #==> 200 OK
  #==> {
  #==>   "columns" : [ "r" ],
  #    ==>   "data" : [ [ {
  #                       ==>     "start" : "http://localhost:7474/db/data/node/1",
  #    ==>     "data" : {
  #==>       "since" : 2000
  #==>     },
  #    ==>     "self" : "http://localhost:7474/db/data/relationship/3",
  #    ==>     "property" : "http://localhost:7474/db/data/relationship/3/properties/{key}",
  #    ==>     "properties" : "http://localhost:7474/db/data/relationship/3/properties",
  #    ==>     "type" : "friends",
  #    ==>     "extensions" : {
  #==>     },
  #    ==>     "end" : "http://localhost:7474/db/data/node/214"
  #==>   } ] ]
  class CypherRelationship < Neo4j::Relationship
    include Neo4j::Server::Resource

    def initialize(db)
      @db = db
    end

    def neo_id
      resource_url_id
    end

    def start_node
      id = resource_url_id(resource_url(:start))
      Neo4j::Node.load(id)
    end

    def end_node
      id = resource_url_id(resource_url(:end))
      Neo4j::Node.load(id)
    end

    def get_property(key)
      id = neo_id
      r = @db.query{rel(id)[key]}
      expect_response_code(r.response, 200)
      r.first_data
    end

    def set_property(key,value)
      id = neo_id
      r = @db.query{rel(id)[key]=value}
      expect_response_code(r.response, 200)
    end

    def remove_property(key)
      id = neo_id
      r = @db.query{rel(id)[key]=:NULL}
      expect_response_code(r.response, 200)
    end

    def del
      id = neo_id
      @db.query{rel(id).del}.raise_unless_response_code(200)
    end

    def exist?
      id = neo_id
      response = @db.query{rel(id)}

      if (!response.error?)
        return true
      elsif (response.exception == 'BadInputException') # TODO see github issue neo4j/1061
        return false
      else
        handle_response_error(response.response)
      end
    end

  end
end