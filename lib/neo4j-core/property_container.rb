module Neo4j
  module PropertyContainer
    module Rest
      def ==(other)
        @id == other.id
      end

      # Properties
      def [](*keys)
        keys.map!(&:to_s)
        properties = props # Fetch all properties as this is more efficient than firing a HTTP request for every key
        result = []
        keys.each { |k| result << properties[k] }
        # If a single key was asked then return it's value else return an array of values in the correct order
        if keys.length == 1
          result.first
        else
          result
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def []=(*keys, values)
        # Flattent the values to 1 level. This creates an arrray of values in the case only a single value is provided.
        values = [values].flatten(1)
        keys.map!(&:to_s)
        properties = props
        Hash[keys.zip(values)].each { |k, v| properties[k] = v unless k.nil? }
        self.props = properties # Reset all the properties - write simple inefficient code until it proves inefficient
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def props
        _get_properties || {}
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def props=(attributes)
        attributes.delete_if { |key, value| key.nil? || value.nil? } # Remove keys-value pairs where either is nil
        _reset_properties(attributes)
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def delete
        _delete
        _set_private_vars_to_nil
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def destroy
        _destroy # Delete the entity after deleting connected entities
        _set_private_vars_to_nil
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      private
        def _raise_doesnt_exist_anymore_error(e)
          if @session.nil?
            nil
          else
            raise e
          end
        end

        def _abstract
          raise "No properties"
        end

        alias :_get_properties :_abstract
        alias :_reset_properties :_abstract
        alias :_set_private_vars_to_nil :_abstract
        alias :_delete :_abstract
        alias :_destroy :_abstract
    end

    module Embedded
      def id
        get_id
      end

      def ==(other)
        id == other.id
      end

      # Properties
      def [](*keys)
        keys = _serialize(keys)
        result = []
        keys.each do |k|
          # Result contains the values for the keys asked or nil if they key does not exist
          result << if has_property(k)
            get_property(k)
          else
            nil
          end
        end
        # If a single key was asked then return it's value else return an array of values in the correct order
        if keys.length == 1
          result.first
        else
          result
        end
      end

      def []=(*keys, values)
        # Flattent the values to 1 level. This creates an arrray of values in the case only a single value is provided.
        values = [values].flatten(1)
        attributes = Hash[keys.zip values]
        nil_values = lambda { |_, v| v.nil? } # Resusable lambda
        keys_to_delete = attributes.select(&nil_values).keys # Get the keys to be removed
        attributes.delete_if(&nil_values) # Now remove those keys from attributes
        keys_to_delete.each { |k| remove_property(k) if has_property(k) } # Remove the keys to be deleted if they are valid
        attributes = _serialize(attributes)
        attributes.each { |k, v| set_property(k, v) } # Set key-value pairs for remaining attributes
      end

      def props
        result = {} # Initialize results
        get_property_keys.each { |key| result[key] = get_property(key) } # Populate the hash with the container's key-value pairs
        result # Return the result
      end

      def props=(attributes)
        attributes.delete_if { |key, value| key.nil? || value.nil? } # Remove keys-value pairs where either is nil before serialization
        attributes = _serialize(attributes)
        get_property_keys.each { |key| remove_property(key) } # Remove all properties
        attributes.each { |key, value| set_property(key, value) } # Set key-value pairs
      end

      def destroy
        _destroy
      end

      private
        # Serialize keys and values into approiate type for conversion to Java objects
        def _serialize(*objects)
          result = objects.map do |obj|
            if obj.is_a?(Hash)
              _serialize_hash(obj)
            else
              _appropriate_type_for obj
            end
          end
          if objects.length == 1
            result.first
          else
            result
          end
        end

        # Convert all keys to strings and values to an appropriate type
        def _serialize_hash(hash)
          attributes = {}
          hash.each { |key, value| attributes[key.to_s] = _appropriate_type_for value }
          attributes
        end

        def _appropriate_type_for(value)
          case value
          when String, Numeric, TrueClass, FalseClass
            value # Will be converted by JRuby
          when Array
            # Convert each of the elements to an appropriate type
            # Convert to a Java array of the first element's type. If the types of all elements don't match then the runtime raises an exception.
            result = value.map { |v| _appropriate_type_for v }
            result.to_java(result.first.class.to_s.downcase.to_sym)
          else
            value.to_s # Try and convert to a string
          end
        end

        def _destroy
          raise "No properties"
        end
    end
  end
end