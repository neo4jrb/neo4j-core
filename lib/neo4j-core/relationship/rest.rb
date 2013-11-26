module Neo4j
  module Relationship
    class Rest
      attr_reader :session, :id, :start, :end, :nodes, :type
      
      def initialize(relationship, session)
        @relationship = relationship
        @session = session
        @id = @relationship["self"].split('/').last.to_i # Set the id
        @start = @session.load(@relationship["start"])
        @end = @session.load(@relationship["end"])
        @nodes = [@start, @end]
        @type  = @relationship["type"]
      end

      def ==(rel)
        @id == rel.id
      end

      # Properties
      def [](*keys)
        keys.map!(&:to_s)
        properties = props
        number_of_results = keys.length
        keys = keys.select { |k| properties[k] }
        properties = @session.neo.get_relationship_properties(@relationship, keys)
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
        raise_doesnt_exist_anymore_error(e)
      end

      def []=(*keys, values)
        values = [values].flatten
        keys.map!(&:to_s)
        properties = props
        attributes = Hash[keys.zip values].select { |k| properties[k] }
        nil_values = lambda { |_, v| v.nil? }
        keys_to_delete = attributes.select(&nil_values).keys
        attributes.delete_if(&nil_values)
        @session.neo.remove_relationship_properties(@relationship, keys_to_delete)
        properties = @session.neo.set_relationship_properties(@relationship, attributes)
        result = keys.map { |key| properties[key] } # Return the result in the correct order
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def props
        @session.neo.get_relationship_properties(@relationship) || {}
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def props=(attributes)
        attributes = attributes.delete_if { |_, value| value.nil? }
        @session.neo.reset_relationship_properties(@relationship, attributes)
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def other_node(node)
        case node
        when @start
          @end
        when @end
          @start
        else
          nil
        end
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def delete
        @session.neo.delete_relationship @relationship
        @relationship = @session = nil
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def destroy
        delete
        @nodes.each {|node| node.delete }
      rescue NoMethodError => e
        raise_doesnt_exist_anymore_error(e)
      end

      def to_s
        "REST Relationship[#{@id}]"
      end

      private
        def raise_doesnt_exist_anymore_error(e)
          if @session.nil?
            raise StandardError.new("Node[#{@id}] does not exist anymore!") 
          else
            raise e
          end
        end
    end
  end
end