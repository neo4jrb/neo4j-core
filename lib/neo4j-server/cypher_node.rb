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
      r = @session._query_internal(self) { |node| node } # TODO
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
      query_cypher_for(:delete_node, neo_id).raise_unless_response_code(200)
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

    def rels(match={})
      dir = match[:dir] || :both
      cypher_rel = match[:type] ? ["r?:`#{match[:type]}`"] : ['r?']
      between_id = match[:between] && match[:between].neo_id

      r = cypher_rels(between_id, cypher_rel, dir)

      r.data.map do |rel|
        next if r.uncommited? ? rel['row'].first.nil? : rel.first.nil?
        id = r.uncommited? ? rel['row'].first : rel.first
        CypherRelationship.new(@session, id)
      end.compact
    end

    def cypher_rels(between_id, cypher_rel, dir)
      case dir
        when :outgoing
          if between_id
            cypher_outgoing_rels_between(cypher_rel, between_id)
          else
            cypher_outgoing_rels(cypher_rel)
          end
        when :incoming
          if between_id
            cypher_incoming_rels_between(cypher_rel, between_id)
          else
            cypher_incoming_rels(cypher_rel)
          end
        when :both
          if between_id
            cypher_both_rels_between(cypher_rel, between_id)
          else
            cypher_both_rels(cypher_rel)
          end
        else
          raise "illegal direction, allowed :outgoing, :incoming and :both for paramter :dir"
      end
    end

    def cypher_outgoing_rels_between(cypher_rel, between_id)
      @session._query_internal(self) {|n| n.outgoing(cypher_rel, node(between_id)); rel.as(:r).neo_id}
    end

    def cypher_outgoing_rels(cypher_rel)
      @session._query_internal(self) {|n| n.outgoing(cypher_rel); rel.as(:r).neo_id}
    end

    def cypher_incoming_rels_between(cypher_rel, between_id)
      @session._query_internal(self) {|n| n.incoming(cypher_rel, node(between_id)); rel.as(:r).neo_id}
    end

    def cypher_incoming_rels(cypher_rel)
      @session._query_internal(self) {|n| n.incoming(cypher_rel); rel.as(:r).neo_id}
    end

    def cypher_both_rels_between(cypher_rel, between_id)
      @session._query_internal(self) {|n| n.both(cypher_rel, node(between_id)); rel.as(:r).neo_id}
    end

    def cypher_both_rels(cypher_rel)
      @session._query_internal(self) {|n| n.both(cypher_rel); rel.as(:r).neo_id}
    end

  end
end