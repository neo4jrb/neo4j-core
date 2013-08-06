module Neo4j::Core::Property
  extend Neo4j::Core::TxMethods

  def valid_property?(value)
    Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.include?(value.class)
  end

  def []=(key,value)
    unless valid_property?(value) # TODO DRY
      raise Neo4j::InvalidPropertyException.new("Not valid Neo4j Property value #{value.class}, valid: #{Neo4j::Node::VALID_PROPERTY_VALUE_CLASSES.to_a.join(', ')}")
    end

    if value.nil?
      remove_property(key)
    else
      set_property(key.to_s, value)
    end
  end
  tx_methods :[]=

  def [](key)
    return nil unless has_property?(key.to_s)
    get_property(key.to_s)
  end

  def neo_id
    get_id
  end
end
