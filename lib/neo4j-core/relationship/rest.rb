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

      def [](*keys)
        keys.map!(&:to_s)
        begin
          props = @session.neo.get_relationship_properties(@relationship, keys)
          result = keys.map { |key| props[key] } # Return the result in the correct order
        rescue Neography::NoSuchPropertyException
          if keys.length == 1
            nil
          else
            []
          end
        end
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def []=(*keys, values)
        values = [values].flatten
        keys.map!(&:to_s)
        attributes = Hash[keys.zip values]
        keys_to_delete = attributes.delete_if { |k, v| v.nil? }.keys
        begin
          @session.neo.remove_relationship_properties(@relationship, keys_to_delete)
          props = @session.neo.set_relationship_properties(@relationship, attributes)
          result = keys.map { |key| props[key] } # Return the result in the correct order
        rescue Neography::NoSuchPropertyException
          if keys.length == 1
            nil
          else
            []
          end
        end
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def props
        @session.neo.get_relationship_properties(@relationship)
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def props=(attributes)
        attributes = attributes.delete_if { |_, value| value.nil? }
        @session.neo.set_relationship_properties(@relationship, attributes)
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def other_node(node)
        if @nodes.include?(node)
          (@nodes - node)[0]
        else
          nil
        end
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def delete
        session.neo.delete_relationship(@relationship)
        @relationship = @session = @start = @end = @nodes = @type = nil
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def to_s
        "REST Relationship[#{@id}]"
      end

      private
        def raise_doesnt_exist_anymore_error
          raise StandardError.new("Relationship[#{@id}] does not exist anymore!")
        end
    end
  end
end