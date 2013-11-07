module Neo4j
  module PropertyContainer
    include Neo4j::PropertyValidator

    # Only documentation here
    def [](key)
      get_property(key)
    end


    def []=(key,value)
      validate_property(value)

      if value.nil?
        remove_property(key)
      else
        set_property(key,value)
      end
    end


    # TODO implement the props method as in the embedded api
  end
end