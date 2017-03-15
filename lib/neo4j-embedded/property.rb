
# TODO: code duplication with the Neo4j::PropertyContainer,
# This module should extend that module by adding transaction around methods
module Neo4j
  module Embedded
    module Property
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
      # Property keys are always strings. Valid property value types are the primitives:
      # (<tt>String</tt>, <tt>Integer</tt>, <tt>Float</tt>, <tt>FalseClass</tt>, <tt>TrueClass</tt>)
      # or an array of those primitives.
      #
      # ==== Gotchas
      # * Values in the array must be of the same type.
      # * You can *not* delete or add one item in the array (e.g. person.phones.delete('123')) but instead you must create a new array instead.
      #
      # @param [String, Symbol] k of the property to set
      # @param [String,Integer,Float,true,false, Array] v to set
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
        hash.each { |k, v| to_java_property(k, v) }
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
        validate_property!(v)

        k = k.to_s
        case v
        when nil then remove_property(k)
        when Array
          set_property(k, v.to_java(java_type_from_value(v[0])))
        else
          set_property(k, v)
        end
      end

      def java_type_from_value(value)
        case value
        when String
          :string
        when Float
          :double
        when FalseClass, TrueClass
          :boolean
        when Integer
          :long
        else
          fail "Not allowed to store array with value #{value.inspect} type #{value.class}"
        end
      end
    end
  end
end
