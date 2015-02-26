module Neo4j
  module Server
    class CypherRelationship < Neo4j::Relationship
      include Neo4j::Server::Resource
      include Neo4j::Core::CypherTranslator
      include Neo4j::Core::ActiveEntity

      def initialize(session, value)
        @session = session
        @response_hash = value
        @rel_type = @response_hash[:type]
        @props = @response_hash[:data]
        @start_node_neo_id = neo_id_integer(@response_hash[:start])
        @end_node_neo_id = neo_id_integer(@response_hash[:end])
        @id = @response_hash[:id]
      end

      def ==(other)
        other.class == self.class && other.neo_id == neo_id
      end
      alias_method :eql?, :==

      attr_reader :id

      def neo_id
        id
      end

      def inspect
        "CypherRelationship #{neo_id}"
      end

      def load_resource
        return if resource_data_present?

        @resource_data = @session._query_or_fail("#{match_start} RETURN n", true, neo_id: neo_id) # r.first_data
      end

      attr_reader :start_node_neo_id

      attr_reader :end_node_neo_id

      def _start_node_id
        @start_node_neo_id ||= get_node_id(:start)
      end

      def _end_node_id
        @end_node_neo_id ||= get_node_id(:end)
      end

      def _start_node
        @_start_node ||= Neo4j::Node._load(start_node_neo_id)
      end

      def _end_node
        load_resource
        @_end_node ||= Neo4j::Node._load(end_node_neo_id)
      end

      def get_node_id(direction)
        load_resource
        resource_url_id(resource_url(direction))
      end

      def get_property(key)
        @session._query_or_fail("#{match_start} RETURN n.`#{key}`", true, neo_id: neo_id)
      end

      def set_property(key, value)
        @session._query_or_fail("#{match_start} SET n.`#{key}` = {value}", false,  value: value, neo_id: neo_id)
      end

      def remove_property(key)
        @session._query_or_fail("#{match_start} REMOVE n.`#{key}`", false, neo_id: neo_id)
      end

      # (see Neo4j::Relationship#props)
      def props
        if @props
          @props
        else
          hash = @session._query_entity_data("#{match_start} RETURN n", nil, neo_id: neo_id)
          @props = Hash[hash[:data].map { |k, v| [k, v] }]
        end
      end

      # (see Neo4j::Relationship#props=)
      def props=(properties)
        @session._query_or_fail("#{match_start} SET n = { props }", false,  props: properties, neo_id: neo_id)
        properties
      end

      # (see Neo4j::Relationship#update_props)
      def update_props(properties)
        return if properties.empty?
        q = "#{match_start} SET " + properties.keys.map do |k|
          "n.`#{k}`= #{escape_value(properties[k])}"
        end.join(',')
        @session._query_or_fail(q, false, neo_id: neo_id)
        properties
      end

      def rel_type
        @rel_type.to_sym
      end

      def del
        @session._query("#{match_start} DELETE n", neo_id: neo_id)
      end
      alias_method :delete, :del
      alias_method :destroy, :del

      def exist?
        response = @session._query("#{match_start} RETURN n", neo_id: neo_id)
        # binding.pry
        (response.data.nil? || response.data.empty?) ? false : true
      end

      private

      def match_start(identifier = 'n')
        "MATCH (node)-[#{identifier}]-() WHERE ID(#{identifier}) = {neo_id}"
      end

      def resource_data_present?
        !resource_data.nil? && !resource_data.empty?
      end

      def neo_id_integer(id_or_url)
        id_or_url.is_a?(Integer) ? id_or_url : id_or_url.match(/\d+$/)[0].to_i
      end
    end
  end
end
