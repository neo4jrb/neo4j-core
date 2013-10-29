module Neo4j::Server
  class CypherNode < Neo4j::Node
    include Neo4j::Server::Resource
    extend Forwardable
    def_delegator :@session, :query_cypher_for

    def initialize(session, id)
      @session = session
      @id = id
    end

    def neo_id
      @id
    end

    def inspect
      "CypherNode #{neo_id} (#{object_id})"
    end

    # TODO, needed by neo4j-cypher
    def _java_node
      self
    end

    def create_rel(type, other_node, props = nil)
      cypher_response = if props
                          query_cypher_for(:create_rels_with_props, neo_id, other_node.neo_id, type, props)
                        else
                          query_cypher_for(:create_rels, neo_id, other_node.neo_id, type)
                        end

      id = cypher_response.first_data
      CypherRelationship.new(@session, id)
    end

    def props
      props = query_cypher_for(:load_node, neo_id).first_data['data']
      props.keys.inject({}){|hash,key| hash[key.to_sym] = props[key]; hash}
    end

    def remove_property(key)
      query_cypher_for(:remove_property, neo_id, key)
    end

    def set_property(key,value)
      query_cypher_for(:set_property, neo_id, key, value)
      value
    end

    def get_property(key)
      r = query_cypher_for(:get_property, neo_id, key)
      r.first_data
    end

    def labels
      r = query_cypher_for(:load_node, neo_id)
      @resource_data = r.first_data  # TODO optitimize !
      url = resource_url('labels')
      response = HTTParty.send(:get, url, headers: resource_headers)

      Enumerator.new do |yielder|
        response.each do |data|
          yielder << data.to_sym
        end
      end
    end

    def del
      r = query_cypher_for(:delete_rels, neo_id)
      r.raise_error if r.error?
      r = query_cypher_for(:delete_node, neo_id)
      r.raise_error if r.error?
    end

    def exist?
      response = query_cypher_for(:get_same_node_id, neo_id)
      if (!response.error?)
        return true
      elsif (response.error_status == 'EntityNotFoundException')
        return false
      else
        response.raise_error
      end
    end


    def node(match={})
      result = match(CypherNode, "ID(p)", match)
      raise "Expected to only find one relationship from node #{neo_id} matching #{match.inspect} but found #{result.count}" if result.count > 1
      result.first
    end

    def rel(match={})
      result = match(CypherRelationship, "ID(r)", match)
      raise "Expected to only find one relationship from node #{neo_id} matching #{match.inspect} but found #{result.count}" if result.count > 1
      result.first
    end

    def rel?(match={})
      result = match(CypherRelationship, "ID(r)", match)
      !!result.first
    end

    def nodes(match={})
      match(CypherNode, "ID(p)", match)
    end

    def match(clazz, returns, match={})
      to_dir = {outgoing: ->(rel) {"-#{rel}->"},
                incoming: ->(rel) {"<-#{rel}-"},
                both:     ->(rel) {"-#{rel}-"} }

      cypher_rel = match[:type] ? "[r:`#{match[:type]}`]" : '[r]'
      between_id = match[:between] ? ",p=node(#{match[:between].neo_id}) " : ""
      dir_func = to_dir[match[:dir] || :both]
      cypher = "START n=node(#{neo_id}) #{between_id} MATCH (n)#{dir_func.call(cypher_rel)}(p) RETURN #{returns}"
      r = @session._query(cypher)
      r.raise_error if r.error?
      _map_result(r, clazz)
    end

    def rels(match={})
      match(CypherRelationship, "ID(r)", match)
    end

    def _map_result(r, clazz)
      r.data.map do |rel|
        next if r.uncommited? ? rel['row'].first.nil? : rel.first.nil?
        id = r.uncommited? ? rel['row'].first : rel.first
        clazz.new(@session, id)
      end.compact
    end

  end
end