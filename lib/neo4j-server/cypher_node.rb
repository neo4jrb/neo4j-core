module Neo4j
  module Server
    class CypherNode < Neo4j::Node
      include Neo4j::Server::Resource
      include Neo4j::Core::CypherTranslator
      include Neo4j::Core::ActiveEntity

      def initialize(session, value)
        @session = session

        @neo_id = if value.is_a?(Hash)
                    @props = value[:data]
                    @labels = value[:metadata][:labels].map!(&:to_sym) if value[:metadata]
                    value[:id]
                  else
                    value
                  end
      end

      attr_reader :neo_id

      def inspect
        "CypherNode #{neo_id} (#{object_id})"
      end

      # TODO, needed by neo4j-cypher
      def _java_node
        self
      end

      # (see Neo4j::Node#create_rel)
      def create_rel(type, other_node, props = nil)
        ids_hash = {start_neo_id: neo_id, end_neo_id: other_node.neo_id}
        props_with_ids = props.nil? ? ids_hash : cypher_prop_list(props).merge(ids_hash)
        id = @session._query_or_fail(rel_string(type, other_node, props), true, props_with_ids)
        data_hash = {type: type, data: props, start: neo_id, end: other_node.neo_id, id: id}
        CypherRelationship.new(@session, data_hash)
      end

      def rel_string(type, other_node, props)
        "MATCH (a), (b) WHERE ID(a) = {start_neo_id} AND ID(b) = {end_neo_id} CREATE (a)-[r:`#{type}` #{prop_identifier(props)}]->(b) RETURN ID(r)"
      end

      # (see Neo4j::Node#props)
      def props
        if @props
          @props
        else
          hash = @session._query_entity_data("#{match_start} RETURN n", nil, neo_id: neo_id)
          @props = Hash[hash[:data].map { |k, v| [k, v] }]
        end
      end

      def refresh
        @props = nil
      end

      # (see Neo4j::Node#remove_property)
      def remove_property(key)
        refresh
        @session._query_or_fail("#{match_start} REMOVE n.`#{key}`", false,  neo_id: neo_id)
      end

      # (see Neo4j::Node#set_property)
      def set_property(key, value)
        refresh
        @session._query_or_fail("#{match_start} SET n.`#{key}` = { value }", false,  value: value, neo_id: neo_id)
        value
      end

      # (see Neo4j::Node#props=)
      def props=(properties)
        refresh
        @session._query_or_fail("#{match_start} SET n = { props }", false,  props: properties, neo_id: neo_id)
        properties
      end

      def remove_properties(properties)
        return if properties.empty?

        refresh
        q = "#{match_start} REMOVE " + properties.map do |k|
          "n.`#{k}`"
        end.join(', ')
        @session._query_or_fail(q, false, neo_id: neo_id)
      end

      # (see Neo4j::Node#update_props)
      def update_props(properties)
        refresh
        return if properties.empty?

        removed_keys = properties.keys.select { |k| properties[k].nil? }
        remove_properties(removed_keys)
        properties_to_set = properties.keys - removed_keys

        return if properties_to_set.empty?
        props_list = cypher_prop_list(properties)[:props].merge(neo_id: neo_id)
        @session._query_or_fail("#{match_start} SET #{cypher_properties(properties_to_set)}", false, props_list)

        properties
      end

      # (see Neo4j::Node#get_property)
      def get_property(key)
        @props ? @props[key.to_sym] : @session._query_or_fail("#{match_start} RETURN n.`#{key}`", true, neo_id: neo_id)
      end

      # (see Neo4j::Node#labels)
      def labels
        @labels ||= @session._query_or_fail("#{match_start} RETURN labels(n) as labels", true, neo_id: neo_id).map!(&:to_sym)
      end

      def _cypher_label_list(labels_list)
        ':' + labels_list.map { |label| "`#{label}`" }.join(':')
      end

      def add_label(*new_labels)
        @session._query_or_fail("#{match_start} SET n #{_cypher_label_list(new_labels)}", false, neo_id: neo_id)
        new_labels.each { |label| labels << label }
      end

      def remove_label(*target_labels)
        @session._query_or_fail("#{match_start} REMOVE n #{_cypher_label_list(target_labels)}", false, neo_id: neo_id)
        target_labels.each { |label| labels.delete(label) } unless labels.nil?
      end

      def set_label(*label_names)
        q = "#{match_start} #{remove_labels_if_needed} #{set_labels_if_needed(label_names)}"
        @session._query_or_fail(q, false, neo_id: neo_id)
      end

      # (see Neo4j::Node#del)
      def del
        @session._query_or_fail("#{match_start} OPTIONAL MATCH n-[r]-() DELETE n, r", false, neo_id: neo_id)
      end

      alias_method :delete, :del
      alias_method :destroy, :del

      # (see Neo4j::Node#exist?)
      def exist?
        @session._query("#{match_start} RETURN ID(n)", neo_id: neo_id).data.empty? ? false : true
      end

      # (see Neo4j::Node#node)
      def node(match = {})
        ensure_single_relationship { match(CypherNode, 'p as result LIMIT 2', match) }
      end

      # (see Neo4j::Node#rel)
      def rel(match = {})
        ensure_single_relationship { match(CypherRelationship, 'r as result LIMIT 2', match) }
      end

      # (see Neo4j::Node#rel?)
      def rel?(match = {})
        result = match(CypherRelationship, 'r as result', match)
        !!result.first
      end

      # (see Neo4j::Node#nodes)
      def nodes(match = {})
        match(CypherNode, 'p as result', match)
      end

      # (see Neo4j::Node#rels)
      def rels(match = {dir: :both})
        match(CypherRelationship, 'r as result', match)
      end

      # @private
      def match(clazz, returns, match = {})
        cypher_rel = match[:type] ? "[r:`#{match[:type]}`]" : '[r]'
        query = self.query

        query = query.match(:p).where(p: {neo_id: match[:between].neo_id}) if match[:between]

        r = query.match("(n)#{relationship_arrow(cypher_rel, match[:dir])}(p)").return(returns).response

        r.raise_error if r.error?

        _map_result(r)
      end

      def _map_result(r)
        r.to_node_enumeration.map(&:result)
      end

      def query(identifier = :n)
        @session.query.match(identifier).where(identifier => {neo_id: neo_id})
      end

      private

      def cypher_properties(properties_to_set)
        properties_to_set.map! { |k| "n.`#{k}` = {`#{k}`}" }.join(',')
      end

      def remove_labels_if_needed
        if labels.empty?
          ''
        else
          " REMOVE n #{_cypher_label_list(labels)}"
        end
      end

      def relationship_arrow(rel_spec, direction = nil)
        case direction || :both
        when :outgoing then "-#{rel_spec}->"
        when :incoming then "<-#{rel_spec}-"
        when :both then "-#{rel_spec}-"
        else
          fail "Invalid value for relationship_arrow direction: #{direction.inspect}"
        end
      end

      def set_labels_if_needed(label_names)
        if label_names.empty?
          ''
        else
          " SET n #{_cypher_label_list(label_names.map(&:to_sym).uniq)}"
        end
      end

      def ensure_single_relationship(&block)
        result = yield
        fail "Expected to only find one relationship from node #{neo_id} matching #{match.inspect} but found #{result.count}" if result.count > 1
        result.first
      end

      def match_start(identifier = 'n')
        "MATCH (#{identifier}) WHERE ID(#{identifier}) = {neo_id}"
      end
    end
  end
end
