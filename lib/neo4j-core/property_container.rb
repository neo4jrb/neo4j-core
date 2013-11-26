module Neo4j
  module PropertyContainer
    module ClassMethods
      
    end
    
    module InstanceMethods
      def ==(other)
        @id == other.id
      end

      # Properties
      def [](*keys)
        keys.map!(&:to_s)
        properties = props
        number_of_results = keys.length
        keys = keys.select { |k| properties[k] }
        properties = _get_properties(keys)
        result = Array.new(number_of_results)
        for i in 0...keys.length
          result[i] = properties[keys[i]]
        end
        if number_of_results == 1
          result.first
        else
          result
        end
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def []=(*keys, values)
        values = [values].flatten
        keys.map!(&:to_s)
        properties = props
        attributes = Hash[keys.zip values].select { |k| properties[k] }
        nil_values = lambda { |_, v| v.nil? }
        keys_to_delete = attributes.select(&nil_values).keys
        attributes.delete_if(&nil_values)
        _remove_properties(keys_to_delete)
        properties = _set_properties(attributes)
        result = keys.map { |key| properties[key] } # Return the result in the correct order
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def props
        _get_properties || {}
      rescue NoMethodError => e
        _raise_doesnt_exist_anymore_error(e)
      end

      def props=(attributes)
        attributes = attributes.delete_if { |_, value| value.nil? }
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
        _destroy
        _set_private_vars_to_nil
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      private
        def _raise_doesnt_exist_anymore_error(e)
          if @session.nil?
            raise StandardError.new("#{self} does not exist anymore!") 
          else
            raise e
          end
        end

        def _abstract
          raise "No properties"
        end

        alias :_get_properties :_abstract
        alias :_set_properties :_abstract
        alias :_reset_properties :_abstract
        alias :_remove_properties :_abstract
        alias :_set_private_vars_to_nil :_abstract
        alias :_delete :_abstract
        alias :_destroy :_abstract
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end