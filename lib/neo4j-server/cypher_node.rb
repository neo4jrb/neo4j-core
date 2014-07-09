module Neo4j::Server
  class CypherNode < Neo4j::Node
    include Neo4j::Server::Resource
    include Neo4j::Core::CypherTranslator

    def initialize(session, value)
      @session = session

      @id = if value.is_a?(Hash)
        @response_hash = value
        @props = @response_hash['data']
        @response_hash['self'].match(/\d+$/)[0].to_i
      else
        value
      end
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

    # (see Neo4j::Node#create_rel)
    def create_rel(type, other_node, props = nil)
      q = "START a=node(#{neo_id}), b=node(#{other_node.neo_id}) CREATE (a)-[r:`#{type}` #{cypher_prop_list(props)}]->(b) RETURN ID(r)"
      id = @session._query_or_fail(q, true)
      CypherRelationship.new(@session, id, type)
    end

    # (see Neo4j::Node#props)
    def props
      if @props
        @props
      else
        props = @session._query_or_fail("START n=node(#{neo_id}) RETURN n", true)['data']
        props.keys.inject({}){|hash,key| hash[key.to_sym] = props[key]; hash}
      end
    end

    # (see Neo4j::Node#remove_property)
    def remove_property(key)
      @session._query_or_fail("START n=node(#{neo_id}) REMOVE n.`#{key}`")
    end

    # (see Neo4j::Node#set_property)
    def set_property(key,value)
      @session._query_or_fail("START n=node(#{neo_id}) SET n.`#{key}` = { value }", false, value: value)
      value
    end

    # (see Neo4j::Node#props=)
    def props=(properties)
      @session._query_or_fail("START n=node(#{neo_id}) SET n = { props }", false, {props: properties})
      properties
    end

    def remove_properties(properties)
      q = "START n=node(#{neo_id}) REMOVE " + properties.map do |k|
        "n.`#{k}`"
      end.join(', ')
      @session._query_or_fail(q)
    end

    # (see Neo4j::Node#update_props)
    def update_props(properties)
      return if properties.empty?

      removed_keys = properties.keys.select{|k| properties[k].nil?}
      remove_properties(removed_keys) unless removed_keys.empty?
      properties_to_set = properties.keys - removed_keys
      return if properties_to_set.empty?
      q = "START n=node(#{neo_id}) SET " + properties_to_set.map do |k|
        "n.`#{k}`= #{escape_value(properties[k])}"
      end.join(',')
      @session._query_or_fail(q)
      properties
    end

    # (see Neo4j::Node#get_property)
    def get_property(key)
      @session._query_or_fail("START n=node(#{neo_id}) RETURN n.`#{key}`", true)
    end

    # (see Neo4j::Node#labels)
    def labels
      r = @session._query_or_fail("START n=node(#{neo_id}) RETURN labels(n) as labels", true)
      r.map(&:to_sym)
    end

    def _cypher_label_list(labels)
      ':' + labels.map{|label| "`#{label}`"}.join(':')
    end

    def add_label(*labels)
      @session._query_or_fail("START n=node(#{neo_id}) SET n #{_cypher_label_list(labels)}")
    end

    def remove_label(*labels)
      @session._query_or_fail("START n=node(#{neo_id}) REMOVE n #{_cypher_label_list(labels)}")
    end

    def set_label(*label_names)
      label_as_symbols = label_names.map(&:to_sym)
      to_keep = labels & label_as_symbols
      to_remove = labels - to_keep
      to_set = label_as_symbols - to_keep

      # no change ?
      return if to_set.empty? && to_remove.empty?

      q = "START n=node(#{neo_id})"
      q += " SET n #{_cypher_label_list(to_set)}" unless to_set.empty?
      q += " REMOVE n #{_cypher_label_list(to_remove)}" unless to_remove.empty?

      @session._query_or_fail(q)
    end

    # (see Neo4j::Node#del)
    def del
      @session._query_or_fail("START n = node(#{neo_id}) MATCH n-[r]-() DELETE r")
      @session._query_or_fail("START n = node(#{neo_id}) DELETE n")
    end

    # (see Neo4j::Node#exist?)
    def exist?
      response = @session._query("START n=node(#{neo_id}) RETURN ID(n)")
      if (!response.error?)
        return true
      elsif (response.error_status == 'EntityNotFoundException')
        return false
      else
        response.raise_error
      end
    end


    # (see Neo4j::Node#node)
    def node(match={})
      result = match(CypherNode, "ID(p)", match)
      raise "Expected to only find one relationship from node #{neo_id} matching #{match.inspect} but found #{result.count}" if result.count > 1
      result.first
    end

    # (see Neo4j::Node#rel)
    def rel(match={})
      result = match(CypherRelationship, "ID(r), TYPE(r)", match)
      raise "Expected to only find one relationship from node #{neo_id} matching #{match.inspect} but found #{result.count}" if result.count > 1
      result.first
    end

    # (see Neo4j::Node#rel?)
    def rel?(match={})
      result = match(CypherRelationship, "ID(r), TYPE(r)", match)
      !!result.first
    end

    # (see Neo4j::Node#nodes)
    def nodes(match={})
      match(CypherNode, "ID(p)", match)
    end


    # (see Neo4j::Node#rels)
    def rels(match = {dir: :both})
      match(CypherRelationship, "ID(r), TYPE(r)", match)
    end

    # @private
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

    # @private
    def _map_result(r, clazz)
      r.data.map do |rel|
        next if r.uncommited? ? rel['row'].first.nil? : rel.first.nil?
        row = r.uncommited? ? rel['row'] : rel
        clazz.new(@session, *row).wrapper
      end.compact
    end

  end
end
