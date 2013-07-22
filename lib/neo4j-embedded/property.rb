module Neo4j::Embedded::Property
  extend Neo4j::Core::TxMethods
  def []=(key,value)
    set_property(key.to_s, value)
  end
  tx_methods :[]=

  def [](key)
    get_property(key.to_s)
  end

  def neo_id
    get_id
  end
end
