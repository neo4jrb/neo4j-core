module Neo4j::Server
  class RestDatabase
    include Resource

    def initialize(endpoint_url)
      response = HTTParty.get(endpoint_url)
      data = JSON.parse(response.body)
      RestNode.init_resource_data(data, endpoint_url)
      Neo4j::Database.set_instance(self)
    end

    def shutdown()
      raise "Can't shutdown Neo4j::Server database (try the unregister method instead)"
    end

    def unregister
      Neo4j::Database.set_instance(nil)
    end

    def driver_for(clazz)
      # TODO
      RestNode
    end

  end
end