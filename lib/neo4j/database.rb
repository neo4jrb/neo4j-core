module Neo4j

  # TODO the common YARD docs for different types of databases
  class Database

    def query
    end

    def _query
    end

    def start
    end

    def shutdown
    end

    def unregister
    end

    def register
    end

    def self.instance
      @instance
    end

    def self.register_instance(db)
      @instance ||= db
    end

    def self.unregister_instance(db)
      @instance = nil if @instance == db
    end
  end

end
