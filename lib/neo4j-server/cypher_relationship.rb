module Neo4j::Server

  class CypherRelationship < Neo4j::Relationship
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator
    include Neo4j::Core::ActiveEntity

    def initialize(session, value)
      @session = session
      @response_hash = value
      @rel_type = @response_hash['type']
      @props = @response_hash['data']
      @start_node_neo_id = @response_hash['start'].match(/\d+$/)[0].to_i
      @end_node_neo_id = @response_hash['end'].match(/\d+$/)[0].to_i
      @id = @response_hash['id']
    end

    def ==(o)
      o.class == self.class && o.neo_id == neo_id
    end
    alias_method :eql?, :==

    def id
      @id
    end

    def neo_id
      id
    end

    def inspect
      "CypherRelationship #{neo_id}"
    end

    def load_resource
      if resource_data.nil? || resource_data.empty?
        @resource_data = @session._query_or_fail("START n=relationship(#{id}) RETURN n", true) # r.first_data
      end
    end

    def start_node_neo_id
      @start_node_neo_id
    end

    def end_node_neo_id
      @end_node_neo_id
    end

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
      @session._query_or_fail("START n=relationship(#{id}) RETURN n.`#{key}`", true)
    end

    def set_property(key,value)
      @session._query_or_fail("START n=relationship(#{id}) SET n.`#{key}` = {value}", false, {value: value})
    end

    def remove_property(key)
      @session._query_or_fail("START n=relationship(#{id}) REMOVE n.`#{key}`")
    end

    # (see Neo4j::Relationship#props)
    def props
      if @props
        @props
      else
        hash = @session._query_entity_data("START n=relationship(#{neo_id}) RETURN n")
        @props = Hash[hash['data'].map{ |k, v| [k.to_sym, v] }]
      end
    end

    # (see Neo4j::Relationship#props=)
    def props=(properties)
      @session._query_or_fail("START n=relationship(#{neo_id}) SET n = { props }", false, {props: properties})
      properties
    end

    # (see Neo4j::Relationship#update_props)
    def update_props(properties)
      return if properties.empty?
      q = "START n=relationship(#{neo_id}) SET " + properties.keys.map do |k|
        "n.`#{k}`= #{escape_value(properties[k])}"
      end.join(',')
      @session._query_or_fail(q)
      properties
    end

    def rel_type
      @rel_type.to_sym
    end

    def del
      id = neo_id
      @session._query("START n=relationship(#{id}) DELETE n").raise_unless_response_code(200)
    end

    def exist?
      id = neo_id
      response = @session._query("START n=relationship(#{id}) RETURN n")

      if (!response.error?)
        return true
      elsif (response.error_status == 'BadInputException') # TODO see github issue neo4j/1061
        return false
      else
        response.raise_error
      end
    end

  end
end
