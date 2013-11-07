module Neo4j
  module PropertyValidator

    class InvalidPropertyException < Exception

    end

    # the valid values on a property, and arrays of those.
    VALID_PROPERTY_VALUE_CLASSES = Set.new([Array, NilClass, String, Float, TrueClass, FalseClass, Fixnum])

    # @param [Object] value the value we want to check if it's a valid neo4j property value
    # @return [True, False] A false means it can't be persisted.
    def valid_property?(value)
      VALID_PROPERTY_VALUE_CLASSES.include?(value.class)
    end

    def validate_property(value)
      unless valid_property?(value)
        raise Neo4j::PropertyValidator::InvalidPropertyException.new("Not valid Neo4j Property value #{value.class}, valid: #{Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.to_a.join(', ')}")
      end
    end
  end
end