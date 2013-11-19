module Neo4j
  module Relationship
    class Rest
      attr_reader :session, :id, :start, :end, :nodes
      
      def initialize(relationship, session, start_node, end_node, name)
        if start_node.session != end_node.session
          raise "Cannot create relationship between nodes from different sessions: #{start_node.sessions} and #{end_node.sessions}"
        end
        @relationship = relationship
        @session = session
        @id = node["self"].split('/').last.to_i # Set the id
        @start = start_node
        @end = end_node
        @nodes = [@start, @end]
        @name  = name.to_s
      end

      def [](*keys)
        keys.map!(&:to_s)
        begin
          props = @session.neo.get_relationship_properties(@relationship, keys)
          result = keys.map { |key| props[key] } # Return the result in the correct order
        rescue Neography::NoSuchPropertyException
          nil
        end
      rescue NoMethodError
        raise_doesnt_exist_anymore_error
      end

      def []=(*keys, *values)
        keys.map!(&:to_s)
        values += [nil] * (keys.length - values.length) if keys.length > values.length
        begin
          @session.neo.set_relationship_properties(@relationship, Hash[keys.zip values])
          result = keys.map { |key| props[key] } # Return the result in the correct order
        rescue Neography::NoSuchPropertyException
          nil
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
        @relationship = @session = @start = @end = @nodes = nil
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