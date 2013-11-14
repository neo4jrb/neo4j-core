
# TODO code duplication with the Neo4j::PropertyContainer,
# This module should extend that module by adding transaction around methods
module Neo4j::Embedded::Property
  include Neo4j::PropertyValidator
  include Neo4j::PropertyContainer
  extend Neo4j::Core::TxMethods

  # inherit the []= method but add auto transaction around it
  tx_methods :[]=

  def [](key)
    return nil unless has_property?(key.to_s)
    get_property(key.to_s)
  end
  tx_methods :[]

  def props
    property_keys.inject({}) do |ret, key|
      ret[key.to_sym] = get_property(key)
      ret
    end
  end
  tx_methods :props


  def props=(hash)
    property_keys.each do |key|
      remove_property(key)
    end

    hash.each_pair do |k,v|
      set_property(k,v)
    end
    hash
  end
  tx_methods :props=


  def neo_id
    get_id
  end
end
