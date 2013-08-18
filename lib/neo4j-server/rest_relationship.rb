module Neo4j::Server
  class RestRelationship < Neo4j::Relationship
    include Neo4j::Server::Resource
    include Neo4j::Server::RestEntity

    def initialize(db, response, url=nil)
      @db = db
      init_resource_data(response, response['self'])
    end

    def inspect
      "RestRelationship #{neo_id}, start #{resource_url_id(resource_url(:start))} end #{resource_url_id(resource_url(:end))} (#{object_id})"
    end

    def start_node
      id = resource_url_id(resource_url(:start))
      Neo4j::Node.load(id)
    end

    def end_node
      id = resource_url_id(resource_url(:end))
      Neo4j::Node.load(id)
    end


  end
end