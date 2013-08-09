module Neo4j
  module Properties

    # the valid values on a property, and arrays of those.
    VALID_PROPERTY_VALUE_CLASSES = Set.new([Array, NilClass, String, Float, TrueClass, FalseClass, Fixnum])

    # Only documentation here
    def [](key)
      get_property(key)
    end


    def []=(key,value)
      unless valid_property?(value)
        raise Neo4j::InvalidPropertyException.new("Not valid Neo4j Property value #{value.class}, valid: #{Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.to_a.join(', ')}")
      end

      if value.nil?
        remove_property(key)
      else
        set_property(key,value)
      end
    end

  end
end