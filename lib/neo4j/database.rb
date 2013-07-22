module Neo4j

  class Database
    def self.instance
      @instance
    end

    def self.set_instance(db)
      @instance = db
    end
  end

end
