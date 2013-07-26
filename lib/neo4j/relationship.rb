module Neo4j
  class Relationship
    class << self
      def new(props=nil, db = Neo4j::Database.instance)
        driver = Neo4j::Database.instance.driver_for(Neo4j::Relationship)
        driver.create_relationship(props)
      end

      def load(neo_id, db = Neo4j::Database.instance)
        driver = db.driver_for(Neo4j::Relationship)
        driver.load(neo_id)
      end

    end
  end
end