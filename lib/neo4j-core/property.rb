module Neo4j::Core::Property
  extend Neo4j::Core::TxMethods
  def []=(key,value)
    set_property(key.to_s, value)
  end
  tx_methods :[]=

  def [](key)
    get_property(key.to_s)
  end
end
