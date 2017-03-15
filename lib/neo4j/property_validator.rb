module Neo4j
  module PropertyValidator
    require 'set'
    class InvalidPropertyException < Exception
    end

    # the valid values on a property, and arrays of those.
    VALID_PROPERTY_VALUE_CLASSES = Set.new([Array, NilClass, String, Float, TrueClass, FalseClass, Integer])

    # @param [Object] value the value we want to check if it's a valid neo4j property value
    # @return [True, False] A false means it can't be persisted.
    def valid_property?(value)
      VALID_PROPERTY_VALUE_CLASSES.any? { |c| value.is_a?(c) }
    end

    def validate_property!(value)
      return if valid_property?(value)

      fail Neo4j::PropertyValidator::InvalidPropertyException, "Not valid Neo4j Property value #{value.class}, valid: #{Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.to_a.join(', ')}"
    end
  end
end
