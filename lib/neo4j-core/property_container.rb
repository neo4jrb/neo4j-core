module Neo4j
  module PropertyContainer
    def ==(other)
      @id == other.id
    end

    # Properties
    def [](*keys)
      keys.map!(&:to_s)
      properties = props
      result = []
      keys.each { |k| result << properties[k] }
      if keys.length == 1
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
      attributes.delete_if { |_, value| value.nil? }
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
      alias :_reset_properties :_abstract
      alias :_set_private_vars_to_nil :_abstract
      alias :_delete :_abstract
      alias :_destroy :_abstract
  end
end