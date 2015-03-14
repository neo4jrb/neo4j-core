module Neo4j
  module PropertyContainer
    include Neo4j::PropertyValidator

    # Returns the Neo4j Property of given key
    def [](key)
      get_property(key)
    end

    # Sets the neo4j property
    def []=(key, value)
      validate_property!(value)

      set_property(key, value)
    end
  end
end
