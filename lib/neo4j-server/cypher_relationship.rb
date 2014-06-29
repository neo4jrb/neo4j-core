module Neo4j::Server

  class CypherRelationship < Neo4j::Relationship
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator

    attr_reader :start_node_neo_id, :end_node_neo_id

    def initialize(session, value, rel_type = nil)
      @session = session

      @id = if value.is_a?(Hash)
        @response_hash = value
        @rel_type = @response_hash['type']
        @props = @response_hash['data']
        @start_node_neo_id = @response_hash['start'].match(/\d+$/)[0].to_i
        @end_node_neo_id = @response_hash['end'].match(/\d+$/)[0].to_i

        @response_hash['self'].match(/\d+$/)[0].to_i
      else
        @rel_type = rel_type

        value
      end
    end

    def ==(o)
      o.class == self.class && o.neo_id == neo_id
    end
    alias_method :eql?, :==

    def neo_id
      @id
    end

    def inspect
      "CypherRelationship #{neo_id}"
    end

    def load_resource
      id = neo_id
      unless @resource_data
        @resource_data = @session._query_or_fail("START n=relationship(#{id}) RETURN n", true) # r.first_data
      end
    end

    def _start_node
      load_resource
      id = resource_url_id(resource_url(:start))
      Neo4j::Node._load(id)
    end

    def _end_node
      load_resource
      id = resource_url_id(resource_url(:end))
      Neo4j::Node._load(id)
    end

    def get_property(key)
      id = neo_id
      @session._query_or_fail("START n=relationship(#{id}) RETURN n.`#{key}`", true)
    end

    def set_property(key,value)
      id = neo_id
      @session._query_or_fail("START n=relationship(#{id}) SET n.`#{key}` = {value}", false, {value: value})
    end

    def remove_property(key)
      id = neo_id
      @session._query_or_fail("START n=relationship(#{id}) REMOVE n.`#{key}`")
    end

    # (see Neo4j::Relationship#props)
    def props
      if @props
        @props
      else
        props = @session._query_or_fail("START n=relationship(#{neo_id}) RETURN n", true)['data']
        props.keys.inject({}){|hash,key| hash[key.to_sym] = props[key]; hash}
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
