
# TODO: code duplication with the Neo4j::PropertyContainer,
# This module should extend that module by adding transaction around methods
module Neo4j::Embedded::Property
  include Neo4j::PropertyValidator
  include Neo4j::PropertyContainer
  extend Neo4j::Core::TxMethods

  # inherit the []= method but add auto transaction around it
  tx_methods :[]=

  def [](key)
    return nil unless has_property?(key.to_s)

    to_ruby_property(key.to_s)
  end
  tx_methods :[]

  # Sets the property of this node.
  # Property keys are always strings. Valid property value types are the primitives(<tt>String</tt>, <tt>Fixnum</tt>, <tt>Float</tt>, <tt>FalseClass</tt>, <tt>TrueClass</tt>) or array of those primitives.
  #
  # ==== Gotchas
  # * Values in the array must be of the same type.
  # * You can *not* delete or add one item in the array (e.g. person.phones.delete('123')) but instead you must create a new array instead.
  #
  # @param [String, Symbol] k of the property to set
  # @param [String,Fixnum,Float,true,false, Array] v to set
  def []=(k, v)
    to_java_property(k, v)
  end
  tx_methods :[]=

  def props
    property_keys.each_with_object({}) do |key, ret|
      ret[key.to_sym] = to_ruby_property(key)
    end
  end
  tx_methods :props

  def props=(hash)
    property_keys.each do |key|
      remove_property(key)
    end
    _update_props(hash)
    hash
  end
  tx_methods :props=

  def _update_props(hash)
    hash.each_pair { |k, v| to_java_property(k, v) }
    hash
  end

  def update_props(hash)
    _update_props(hash)
  end
  tx_methods :update_props

  def neo_id
    get_id
  end

  def refresh
    # nothing is needed in the embedded db since we always asks the database
  end

  private

  def to_ruby_property(key)
    val = get_property(key)
    val.class.superclass == ArrayJavaProxy ? val.to_a : val
  end

  def to_java_property(k, v)
    validate_property(v)

    k = k.to_s
    case v
    when nil
      remove_property(k)
    when Array
      type = case v[0]
             when String
               :string
             when Float
               :double
             when FalseClass, TrueClass
               :boolean
             when Fixnum
               :long
             else
               fail "Not allowed to store array with value #{v[0]} type #{v[0].class}"
             end

      set_property(k, v.to_java(type))
    else
      set_property(k, v)
    end
  end
end
