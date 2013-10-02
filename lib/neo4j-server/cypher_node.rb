module Neo4j::Server
  class CypherNode < Neo4j::Node
    include Neo4j::Server::Resource

    def initialize(db)
      @db = db
    end

    def neo_id
      resource_url_id
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
                          cypher_create_rels_with_props(other_node, type, props)
                        else
                          cypher_create_rels(other_node, type)
                        end

      node_data = cypher_response.first_data

      if cypher_response.uncommited?
        raise "not implemented"
      else
        url = node_data['self']
        CypherRelationship.new(@db).init_resource_data(node_data,url)
      end

    end

    def props
      r = @db.query(self) { |node| node }
      props = r.first_data['data']
      props.keys.inject({}){|hash,key| hash[key.to_sym] = props[key]; hash}
    end

    def remove_property(key)
      @db.query(self) {|node| node[key]=:NULL}
    end

    def set_property(key,value)
      @db.query(self) {|node| node[key]=value}
      value
    end

    def get_property(key)
      r = @db.query(self) {|node| node[key]}
      r.first_data
    end

    def labels
      url = resource_url('labels')
      response = HTTParty.send(:get, url, headers: resource_headers)
      Enumerator.new do |yielder|
        response.each do |data|
          yielder << data
        end
      end
    end

    def del
      @db.query(self) {|node| node.del}.raise_unless_response_code(200)
    end

    def exist?
      response = @db.query(self) {|node| node }
      if (!response.error?)
        return true
      elsif (response.exception == 'EntityNotFoundException')
        return false
      else
        handle_response_error(response.response)
      end
    end

    def rels(match={})
      dir = match[:dir] || :both
      cypher_rel = match[:type] ? ["r?:`#{match[:type]}`"] : ['r?']
      between_id = match[:between] && match[:between].neo_id

      r = cypher_rels(between_id, cypher_rel, dir)

      r.data.map do |rel|
        next if rel[0].nil?
        CypherRelationship.new(@db).init_resource_data(rel[0],rel[0]['self'])
      end.compact
    end

    def cypher_create_rels(other_node, type)
      @db.query(self, other_node) { |start_node, end_node| create_path { start_node > rel(type).as(:r) > end_node }; :r }
    end

    def cypher_create_rels_with_props(other_node, type, props)
      @db.query(self, other_node) { |start_node, end_node| create_path { start_node > rel(type, props).as(:r) > end_node }; :r }
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
      @db.query(self) {|n| n.outgoing(cypher_rel, node(between_id)); :r}
    end

    def cypher_outgoing_rels(cypher_rel)
      @db.query(self) {|n| n.outgoing(cypher_rel); :r}
    end

    def cypher_incoming_rels_between(cypher_rel, between_id)
      @db.query(self) {|n| n.incoming(cypher_rel, node(between_id)); :r}
    end

    def cypher_incoming_rels(cypher_rel)
      @db.query(self) {|n| n.incoming(cypher_rel); :r}
    end

    def cypher_both_rels_between(cypher_rel, between_id)
      @db.query(self) {|n| n.both(cypher_rel, node(between_id)); :r}
    end

    def cypher_both_rels(cypher_rel)
      @db.query(self) {|n| n.both(cypher_rel); :r}
    end

  end
end