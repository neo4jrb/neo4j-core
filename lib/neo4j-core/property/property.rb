module Neo4j
  module Core
    module Property

      # @return [Hash] all properties plus the id of the node with the key <tt>_neo_id</tt>
      def props
        ret = {"_neo_id" => neo_id}
        property_keys.each do |key|
          ret[key] = get_property(key)
        end
        ret
      end

      # Ids are garbage collected over time so they are only guaranteed to be unique during a specific time span:
      # if the node is deleted, it's likely that a new node at some point will get the old id. Note:
      # this makes node ids brittle as public APIs.
      # @return [Fixnum] the unique id of this node.
      def neo_id
        getId
      end

      # @param [#to_s] the property we want to check if it exist.
      # @return [true false] true if the given key exist as a property.
      def property?(key)
        has_property?(key.to_s)
      end

      # Updates this node/relationship's properties by using the provided struct/hash.
      # If the option <code>{:strict => true}</code> is given, any properties present on
      # the node but not present in the hash will be removed from the node, except '_neo_id' and '_classname'
      # The option <code>{:protected_keys => array of strings}</code> is similar to the <code<:strict</code> option, except
      # that it allows you to specify which keys will be protected from being updated or deleted.
      # If neither the protected nor strict option is given then all properties starting with '_' will never be touched.
      #
      # @param [Hash, :each_pair] struct_or_hash the key and value to be set
      # @param [Hash] options further options defining the context of the update
      # @option options [Boolean] :strict any properties present on the node but not present in the hash will be removed from the node if true
      # @option options [Array<String>] :protected_keys the keys that never will be touched
      # @return self
      def update(struct_or_hash, options={})
        protected_keys = %w(_neo_id _classname) if options[:strict]
        protected_keys ||= options[:protected_keys].map(&:to_s) if options[:protected_keys]
        keys_to_delete = props.keys - protected_keys if protected_keys

        struct_or_hash.each_pair do |k, value|
          key = k.to_s
          # do not allow special properties to be mass assigned
          if protected_keys
            keys_to_delete.delete(key)
            next if protected_keys.include?(key)
          else
            next if key[0..0] == '_'
          end

          self[key] = value
        end
        keys_to_delete.each { |key| remove_property(key) } if protected_keys
        self
      end

      # @return the value of the given key or nil if the property does not exist.
      def [](key)
        return unless property?(key)
        val = get_property(key.to_s)
        val.class.superclass == ArrayJavaProxy ? val.to_a : val
      end

      # Sets the property of this node.
      # Property keys are always strings. Valid property value types are the primitives(<tt>String</tt>, <tt>Fixnum</tt>, <tt>Float</tt>, <tt>FalseClass</tt>, <tt>TrueClass</tt>) or array of those primitives.
      #
      # ==== Gotchas
      # * Values in the array must be of the same type.
      # * You can *not* delete or add one item in the array (e.g. person.phones.delete('123')) but instead you must create a new array instead.
      #
      # @param [String, Symbol] key of the property to set
      # @param [String,Fixnum,Float,true,false, Array] value to set
      def []=(key, value)
        k = key.to_s
        if value.nil?
          remove_property(k)
        elsif (Array === value)
          case value[0]
            when NilClass
              set_property(k, [].to_java(:string))
            when String
              set_property(k, value.to_java(:string))
            when Float
              set_property(k, value.to_java(:double))
            when FalseClass, TrueClass
              set_property(k, value.to_java(:boolean))
            when Fixnum
              set_property(k, value.to_java(:long))
            else
              raise "Not allowed to store array with value #{value[0]} type #{value[0].class}"
          end
        else
          set_property(k, value)
        end
      end

    end
  end
end